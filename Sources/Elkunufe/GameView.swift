// © 2026 App-Zilla. Licencia MIT.

import ElkunufeCore
import SpriteKit
import SwiftUI

/// Pantalla de juego provisional: tablero, contadores y navegación entre niveles de la campaña.
/// Los menús completos llegan en la Etapa 5.
struct GameView: View {
    /// Nivel inicial; para desarrollo se puede abrir otro con `-startLevel N` (1…60).
    @State private var model = GameModel(levelIndex: max(0, UserDefaults.standard.integer(forKey: "startLevel") - 1))
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            StripeBand()
            header
            SpriteView(scene: model.scene, preferredFramesPerSecond: 60)
                .accessibilityLabel(Text("Tablero"))
            StripeBand()
        }
        .background(Color(cgColor: Theme.forScheme(colorScheme).background))
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(phases: [.down, .repeat]) { press in handle(press) }
        .onAppear {
            focused = true
            model.scene.setTheme(.forScheme(colorScheme))
        }
        .onChange(of: colorScheme) { _, scheme in
            model.scene.setTheme(.forScheme(scheme))
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button { model.previous() } label: { Label("Anterior", systemImage: "chevron.left") }
                .disabled(!model.hasPrevious)
            Text("Nivel \(model.levelIndex + 1) de \(model.levelCount)")
                .font(.headline)
                .monospacedDigit()
            Button { model.next() } label: { Label("Siguiente", systemImage: "chevron.right") }
                .disabled(!model.hasNext)

            Spacer()

            if model.solved {
                Text("¡Nivel completado!")
                    .font(.headline)
                    .foregroundStyle(Palette.red)
            }

            Spacer()

            Group {
                Text("Movimientos: \(model.moves)")
                Text("Empujes: \(model.pushes) / mínimo \(model.optimalPushes)")
            }
            .monospacedDigit()
            Button { model.undo() } label: { Label("Deshacer", systemImage: "arrow.uturn.backward") }
                .disabled(!model.canUndo)
            Button { model.restart() } label: { Label("Reiniciar", systemImage: "arrow.counterclockwise") }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .upArrow: model.move(.up)
        case .downArrow: model.move(.down)
        case .leftArrow: model.move(.left)
        case .rightArrow: model.move(.right)
        case .return where model.solved: model.next()
        default:
            switch press.characters.lowercased() {
            case "w": model.move(.up)
            case "s": model.move(.down)
            case "a": model.move(.left)
            case "d": model.move(.right)
            case "z": press.modifiers.contains(.shift) ? model.redo() : model.undo()
            case "r": model.restart()
            default: return .ignored
            }
        }
        return .handled
    }
}

#Preview {
    GameView()
        .frame(width: 800, height: 600)
}
