// © 2026 App-Zilla. Licencia MIT.

import ElkununCore
import SwiftUI

/// Menús de la barra de macOS con los atajos del juego.
struct GameCommands: Commands {
    let app: AppModel
    @FocusedValue(\.gameModel) private var game

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Nivel aleatorio nuevo") { app.playNewRandom(app.lastDifficulty) }
                .keyboardShortcut("n")
        }

        CommandGroup(replacing: .undoRedo) {
            Button("Deshacer") { game?.undo() }
                .keyboardShortcut("z")
                .disabled(game?.canUndo != true)
            Button("Rehacer") { game?.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(game?.canRedo != true)
        }

        CommandMenu("Juego") {
            Button("Reiniciar nivel") { game?.restart() }
                .keyboardShortcut("r")
                .disabled(game == nil)
            Button("Pista") { game?.showHint() }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                .disabled(game == nil || game?.solved == true)
            Button(game?.isPaused == true ? "Continuar" : "Pausa") { game?.togglePause() }
                .keyboardShortcut("p")
                .disabled(game == nil || game?.showsVictory == true)
            Divider()
            Button("Siguiente nivel") { game?.next() }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
                .disabled(game?.solved != true)
            Divider()
            Button(Preferences.soundEnabled ? "Silenciar" : "Activar sonido") {
                UserDefaults.standard.set(!Preferences.soundEnabled, forKey: PreferenceKey.soundEnabled)
                AudioEngine.shared.applyVolumes()
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
            Divider()
            Button("Menú principal") { app.showMenu() }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            Button("Campaña") { app.showCampaign() }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            Button("Mejores puntajes") { app.showScores() }
                .keyboardShortcut("b", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: .help) {
            Button("Ayuda de Elkünun") { app.showCredits() }
        }
    }
}
