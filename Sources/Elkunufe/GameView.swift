// © 2026 App-Zilla. Licencia MIT.

import ElkunufeCore
import SpriteKit
import SwiftUI

/// Pantalla de juego: tablero, contadores, pausa, victoria y pistas.
struct GameView: View {
    let game: GameModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PreferenceKey.highContrast) private var highContrast = false
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
        .onChange(of: highContrast) { _, value in
            game.scene.setTheme(.current(colorScheme, highContrast: value))
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button { game.togglePause() } label: { Label("Pausa", systemImage: "pause.fill") }
                .help(Text("Pausa (Esc)"))
            Text(game.title)
                .font(.headline)
                .monospacedDigit()
            if let code = game.levelCode {
                Button { game.copyCode() } label: {
                    Label(code.description, systemImage: "doc.on.doc")
                        .labelStyle(.titleAndIcon)
                        .font(.callout.monospaced())
                }
                .help(Text("Copiar el código para compartir este nivel"))
            }

            Spacer()

            Group {
                Text("Movimientos: \(game.moves)")
                Text("Empujes: \(game.pushes) · mínimo \(game.optimalPushes)")
            }
            .monospacedDigit()
            .foregroundStyle(.secondary)

            Button { game.showHint() } label: {
                Label("Pista", systemImage: game.isComputingHint ? "hourglass" : "lightbulb")
            }
            .help(Text("Pista (H)"))
            .disabled(game.isComputingHint || game.solved)
            Button { game.undo() } label: { Label("Deshacer", systemImage: "arrow.uturn.backward") }
                .help(Text("Deshacer (Z)"))
                .disabled(!game.canUndo)
            Button { game.restart() } label: { Label("Reiniciar", systemImage: "arrow.counterclockwise") }
                .help(Text("Reiniciar (R)"))
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
            Text("Pausa").font(.title.weight(.bold))
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
            FoxImage(size: 72)
            Text("¡Nivel completado!").font(.title.weight(.bold))
            VStack(spacing: 4) {
                Text("Movimientos: \(game.moves)")
                Text("Empujes: \(game.pushes) · mínimo \(game.optimalPushes)")
            }
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
