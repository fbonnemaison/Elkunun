// © 2026 App-Zilla. Licencia MIT.

import AppKit
import ElkunufeCore
import Observation
import SwiftUI

/// Una partida en curso. La escena aplica las reglas y anima; este modelo refleja contadores,
/// gestiona pausa, victoria y pistas, y avisa del progreso a `AppModel`.
@MainActor
@Observable
final class GameModel {
    enum Source: Equatable {
        case campaign(Int)
        case random(LevelCode)
    }

    /// Mensaje temporal sobre el tablero (pistas).
    struct Banner: Equatable {
        let text: String
        let id = UUID()
    }

    let source: Source
    let optimalPushes: Int
    let scene: BoardScene
    @ObservationIgnored private weak var app: AppModel?

    private(set) var moves = 0
    private(set) var pushes = 0
    private(set) var solved = false
    private(set) var canUndo = false
    private(set) var canRedo = false
    private(set) var boxesStored = 0
    private(set) var boxCount = 0
    private(set) var playerPosition = Position(x: 0, y: 0)
    private(set) var hintsUsed = 0
    private(set) var isComputingHint = false
    private(set) var isNewRecord = false
    var banner: Banner?

    /// Pantalla de victoria visible (aparece un momento después de resolver, tras la animación).
    private(set) var showsVictory = false
    var isPaused = false {
        didSet { updateInput() }
    }

    @ObservationIgnored private var hintTask: Task<Void, Never>?

    init(source: Source, level: Level, optimalPushes: Int, app: AppModel) {
        self.source = source
        self.optimalPushes = optimalPushes
        self.app = app
        scene = BoardScene(level: level)
        scene.onChange = { [weak self] state in self?.update(state) }
        scene.onSolved = { [weak self] in self?.didSolve() }
        update(scene.game)
    }

    // MARK: - Datos para la interfaz

    var title: String {
        switch source {
        case .campaign(let i):
            String(localized: "Nivel \(i + 1) de \(Campaign.levelCount)")
        case .random(let code):
            switch code.difficulty {
            case .easy: String(localized: "Nivel aleatorio · fácil")
            case .medium: String(localized: "Nivel aleatorio · medio")
            case .hard: String(localized: "Nivel aleatorio · difícil")
            }
        }
    }

    var levelCode: LevelCode? {
        if case .random(let code) = source { code } else { nil }
    }

    var campaignIndex: Int? {
        if case .campaign(let i) = source { i } else { nil }
    }

    var hasNext: Bool {
        guard let i = campaignIndex else { return true }
        return i + 1 < Campaign.levelCount
    }

    var isOptimal: Bool { solved && pushes <= optimalPushes }

    /// Descripción del tablero para VoiceOver.
    var accessibilityDescription: String {
        String(localized: "Zorro en la columna \(playerPosition.x), fila \(playerPosition.y). Cajas guardadas: \(boxesStored) de \(boxCount). Movimientos: \(moves).")
    }

    // MARK: - Acciones

    func move(_ direction: Direction) {
        guard isPlayable else { return }
        scene.cancelWalk()
        scene.move(direction)
    }

    func undo() {
        guard !isPaused else { return }
        showsVictory = false
        scene.undo()
        updateInput()
    }

    func redo() {
        guard isPlayable else { return }
        scene.redo()
    }

    func restart() {
        isPaused = false
        showsVictory = false
        scene.restart()
        updateInput()
    }

    func togglePause() {
        guard !showsVictory else { return }
        isPaused.toggle()
    }

    /// Siguiente nivel de la campaña, u otro nivel aleatorio de la misma dificultad.
    func next() {
        guard let app else { return }
        switch source {
        case .campaign(let i) where i + 1 < Campaign.levelCount:
            app.playCampaign(i + 1)
        case .campaign:
            app.showCampaign()
        case .random(let code):
            app.playNewRandom(code.difficulty)
        }
    }

    func exitToMenu() {
        hintTask?.cancel()
        switch source {
        case .campaign: app?.showCampaign()
        case .random: app?.showRandom()
        }
    }

    func copyCode() {
        guard let code = levelCode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code.description, forType: .string)
        banner = Banner(text: String(localized: "Código copiado: \(code.description)"))
    }

    func showHint() {
        guard isPlayable, !isComputingHint else { return }
        hintTask?.cancel()
        isComputingHint = true
        let state = scene.game
        hintTask = Task {
            let hint = await Self.computeHint(state)
            guard !Task.isCancelled else { return }
            isComputingHint = false
            // Si el jugador se movió mientras tanto, la pista ya no vale.
            guard scene.game.level == state.level else { return }
            switch hint {
            case .push(let box, let direction, _, let remaining):
                hintsUsed += 1
                AudioEngine.shared.play(.hint)
                scene.showHint(box: box, direction: direction)
                banner = Banner(text: String(localized: "Empuja la caja marcada. Quedan al menos \(remaining) empujes."))
            case .stuck:
                banner = Banner(text: String(localized: "Así ya no tiene solución. Deshaz (Z) o reinicia (R)."))
            case .unknown:
                banner = Banner(text: String(localized: "No encontré una pista a tiempo. Prueba a deshacer algún movimiento."))
            case .solved:
                break
            }
        }
    }

    @concurrent
    private static func computeHint(_ state: GameState) async -> Hint {
        state.hint(isCancelled: { Task.isCancelled })
    }

    // MARK: - Estado

    private var isPlayable: Bool { !isPaused && !showsVictory }

    private func updateInput() {
        scene.isInputEnabled = !isPaused && !showsVictory
    }

    private func update(_ state: GameState) {
        moves = state.moveCount
        pushes = state.pushCount
        solved = state.isSolved
        canUndo = !state.history.isEmpty
        canRedo = !state.redoStack.isEmpty
        boxCount = state.boxes.count
        boxesStored = state.boxes.count(where: { state.board.isGoal($0) })
        playerPosition = Position(x: state.player.x, y: state.player.y)
        if !solved { isNewRecord = false }
    }

    private func didSolve() {
        if let i = campaignIndex {
            isNewRecord = app?.completeCampaign(i, moves: moves, pushes: pushes) ?? false
        }
        AccessibilityNotification.Announcement(String(localized: "¡Nivel completado!")).post()
        Task {
            try? await Task.sleep(for: .milliseconds(Preferences.reduceMotion ? 100 : 700))
            guard solved else { return }
            showsVictory = true
            updateInput()
        }
    }
}
