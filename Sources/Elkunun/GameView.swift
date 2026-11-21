// © 2026 App-Zilla. Licencia MIT.

import ElkununCore
import SpriteKit
import SwiftUI

/// Pantalla de juego: tablero, contadores, pausa, victoria y pistas.
struct GameView: View {
    let game: GameModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PreferenceKey.highContrast) private var highContrast = false
    @AppStorage(PreferenceKey.warnStuck) private var warnStuck = true
    @AppStorage(PreferenceKey.musicEnabled) private var musicEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                SpriteView(scene: game.scene, preferredFramesPerSecond: 60)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Tablero"))
                    .accessibilityValue(Text(game.accessibilityDescription))
                    .accessibilityAction(named: Text("Mover arriba")) { game.move(.up) }
                    .accessibilityAction(named: Text("Mover abajo")) { game.move(.down) }
                    .accessibilityAction(named: Text("Mover a la izquierda")) { game.move(.left) }
                    .accessibilityAction(named: Text("Mover a la derecha")) { game.move(.right) }
                    .accessibilityAction(named: Text("Deshacer")) { game.undo() }
                    .accessibilityAction(named: Text("Pista")) { game.showHint() }

                if let banner = game.banner {
                    VStack {
                        Text(banner.text)
                            .font(.callout.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.top, 8)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: banner) {
                        try? await Task.sleep(for: .seconds(4))
                        withAnimation { if game.banner == banner { game.banner = nil } }
                    }
                }

                if game.isPaused {
                    PauseOverlay(game: game)
                } else if game.showsVictory {
                    VictoryOverlay(game: game)
                }
            }
            .animation(.easeOut(duration: 0.2), value: game.banner)
            .animation(.easeOut(duration: 0.2), value: game.isPaused)
            .animation(.easeOut(duration: 0.25), value: game.showsVictory)
            footer
        }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .focusedSceneValue(\.gameModel, game)
        .onKeyPress(phases: [.down, .repeat]) { press in handle(press) }
        .onAppear {
            focused = true
            game.scene.setTheme(.current(colorScheme, highContrast: highContrast))
        }
        .onChange(of: colorScheme) { _, scheme in
            game.scene.setTheme(.current(scheme, highContrast: highContrast))
        }
        .onChange(of: warnStuck) { game.refreshWarnings() }
        .onChange(of: scenePhase) { _, phase in game.setAppActive(phase == .active) }
        .onDisappear { game.leaveScreen() }
        .onChange(of: musicEnabled) { AudioEngine.shared.applyVolumes() }
        .onChange(of: highContrast) { _, value in
            game.scene.setTheme(.current(colorScheme, highContrast: value))
        }
    }

    // MARK: - Barras

    /// Barra superior: el nivel como título a la izquierda y una burbuja con los controles a la derecha.
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(game.title)
                    .font(.pixel(16))
                    .monospacedDigit()
                if let code = game.levelCode {
                    Button { game.copyCode() } label: {
                        Label(code.description, systemImage: "doc.on.doc")
                            .font(.callout.monospaced())
                    }
                    .buttonStyle(.borderless)
                    .help(Text("Copiar el código para compartir este nivel"))
                }
            }

            Spacer()

            HStack(spacing: 2) {
                BubbleButton(title: "Pista", systemImage: game.isComputingHint ? "hourglass" : "lightbulb",
                             help: "Pista (H)") { game.showHint() }
                    .disabled(game.isComputingHint || game.solved)
                BubbleButton(title: "Deshacer", systemImage: "arrow.uturn.backward", help: "Deshacer (Z)") {
                    game.undo()
                }
                .disabled(!game.canUndo)
                BubbleButton(title: "Reiniciar", systemImage: "arrow.counterclockwise", help: "Reiniciar (R)") {
                    game.restart()
                }
                BubbleButton(title: "Pausa", systemImage: "pause.fill", help: "Pausa (Esc)") {
                    game.togglePause()
                }
                Divider().frame(height: 18).padding(.horizontal, 4)
                BubbleButton(title: musicEnabled ? "Desactivar la música" : "Activar la música",
                             systemImage: musicEnabled ? "music.note" : "music.note.slash",
                             help: musicEnabled ? "Desactivar la música" : "Activar la música") {
                    musicEnabled.toggle()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1)))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    /// Barra inferior con los contadores, el reloj y el aviso de «sin solución».
    private var footer: some View {
        HStack(spacing: 28) {
            if game.isUnsolvable {
                Label("Sin solución", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(red: 0.86, green: 0.12, blue: 0.14))
                    .fontWeight(.semibold)
                    .help(Text("Desde aquí el puzle ya no tiene solución. Deshaz (Z) o reinicia (R)."))
                    .transition(.opacity)
            }
            Label {
                Text("Movimientos: \(game.moves)")
            } icon: {
                Image(systemName: "pawprint.fill")
            }
            Label {
                Text("Empujes: \(game.pushes) · mínimo \(game.optimalPushes)")
            } icon: {
                Image(systemName: "shippingbox.fill")
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Label {
                    Text(formatTime(game.elapsed(at: context.date)))
                } icon: {
                    Image(systemName: "stopwatch")
                }
            }
            .accessibilityLabel(Text("Tiempo"))
        }
        .animation(.easeOut(duration: 0.2), value: game.isUnsolvable)
        .font(.callout)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        // Los atajos con ⌘ los gestiona la barra de menús.
        guard !press.modifiers.contains(.command) else { return .ignored }
        switch press.key {
        case .upArrow: game.move(.up)
        case .downArrow: game.move(.down)
        case .leftArrow: game.move(.left)
        case .rightArrow: game.move(.right)
        case .escape: game.togglePause()
        case .return where game.showsVictory: game.next()
        default:
            switch press.characters.lowercased() {
            case "w": game.move(.up)
            case "s": game.move(.down)
            case "a": game.move(.left)
            case "d": game.move(.right)
            case "z": press.modifiers.contains(.shift) ? game.redo() : game.undo()
            case "r": game.restart()
            case "h": game.showHint()
            default: return .ignored
            }
        }
        return .handled
    }
}

// MARK: - Superposiciones

private struct OverlayCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Rectangle().fill(.black.opacity(0.35)).ignoresSafeArea()
            VStack(spacing: 14) { content }
                .padding(28)
                .frame(minWidth: 320)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 20)
        }
        .transition(.opacity)
    }
}

private struct PauseOverlay: View {
    let game: GameModel

    var body: some View {
        OverlayCard {
            Text("Pausa").font(.pixel(24))
            Button("Continuar") { game.togglePause() }
                .buttonStyle(MenuButtonStyle(prominent: true))
                .keyboardShortcut(.defaultAction)
            Button("Reiniciar nivel") { game.restart() }
                .buttonStyle(MenuButtonStyle())
            Button(game.campaignIndex == nil ? "Volver" : "Elegir nivel") { game.exitToMenu() }
                .buttonStyle(MenuButtonStyle())
        }
    }
}

private struct VictoryOverlay: View {
    let game: GameModel

    var body: some View {
        OverlayCard {
            FoxImage(size: 80)
            Text("¡Nivel completado!").font(.pixel(24))
            VStack(spacing: 4) {
                Text("Movimientos: \(game.moves)")
                Text("Empujes: \(game.pushes) · mínimo \(game.optimalPushes)")
            }
            .monospacedDigit()
            Text("Tiempo: \(formatTime(game.elapsed()))")
                .monospacedDigit()
            if game.isOptimal {
                Label("¡Con el mínimo de empujes!", systemImage: "star.fill")
                    .foregroundStyle(Palette.red)
                    .font(.headline)
            } else if game.isNewRecord, game.campaignIndex != nil {
                Text("¡Nueva mejor marca!").font(.headline)
            }
            if game.hintsUsed > 0 {
                Text("Pistas usadas: \(game.hintsUsed)").foregroundStyle(.secondary)
            }
            Button(nextTitle) { game.next() }
                .buttonStyle(MenuButtonStyle(prominent: true))
                .keyboardShortcut(.defaultAction)
            HStack {
                Button("Repetir") { game.restart() }
                Button(game.campaignIndex == nil ? "Volver" : "Elegir nivel") { game.exitToMenu() }
            }
            .buttonStyle(.borderless)
        }
    }

    private var nextTitle: LocalizedStringKey {
        switch game.source {
        case .campaign where !game.hasNext: "Ver la campaña"
        case .campaign: "Siguiente nivel"
        case .random: "Otro nivel"
        }
    }
}

// MARK: - Valor enfocado para los menús

struct GameModelKey: FocusedValueKey {
    typealias Value = GameModel
}

extension FocusedValues {
    var gameModel: GameModel? {
        get { self[GameModelKey.self] }
        set { self[GameModelKey.self] = newValue }
    }
}

/// Botón de icono dentro de la burbuja de controles, con resaltado al pasar el ratón.
private struct BubbleButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let help: LocalizedStringKey
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 32, height: 28)
                .background(Circle().fill(Color.primary.opacity(hovering && isEnabled ? 0.12 : 0)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.5))
        .onHover { hovering = $0 }
        .help(Text(help))
        .accessibilityLabel(Text(title))
    }
}

/// Tiempo como «m:ss» (o «h:mm:ss» a partir de una hora).
func formatTime(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}
