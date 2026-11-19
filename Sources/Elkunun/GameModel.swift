// © 2026 App-Zilla. Licencia MIT.

import AppKit
import ElkununCore
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
    private(set) var stuckCount = 0
    private(set) var isComputingHint = false
    private(set) var isNewRecord = false
    /// El solucionador confirmó que desde aquí ya no hay solución.
    private(set) var isUnsolvable = false
    var banner: Banner?

    /// Pantalla de victoria visible (aparece un momento después de resolver, tras la animación).
    private(set) var showsVictory = false
    var isPaused = false {
        didSet {
            updateInput()
            updateClock()
        }
    }

    @ObservationIgnored private var hintTask: Task<Void, Never>?
    @ObservationIgnored private var solvabilityTask: Task<Void, Never>?
    @ObservationIgnored private var checkedBoxes: Set<Position>?

    // Reloj: tiempo acumulado más el tramo en curso. Empieza con el primer movimiento y se
    // detiene en pausa, al ganar, al salir de la partida o si la app pasa a segundo plano.
    @ObservationIgnored private var accumulated: TimeInterval = 0
    @ObservationIgnored private var runningSince: Date?
    @ObservationIgnored private var isOnScreen = true
    @ObservationIgnored private var appIsActive = true

    init(source: Source, level: Level, optimalPushes: Int, app: AppModel, resume: SavedSession? = nil) {
        self.source = source
        self.optimalPushes = optimalPushes
        self.app = app
        scene = BoardScene(level: level)
        scene.onChange = { [weak self] state in self?.update(state) }
        scene.onSolved = { [weak self] in self?.didSolve() }
        scene.onStuck = { [weak self] count in self?.didGetStuck(count) }
        if let resume, let state = resume.replay(on: level), !state.isSolved {
            hintsUsed = resume.hintsUsed
            accumulated = resume.elapsedSeconds
            scene.restore(state)
        } else {
            update(scene.game)
        }
    }

    /// Partida guardable que corresponde al estado actual.
    private func session(_ state: GameState) -> SavedSession {
        let savedSource: SavedSession.Source = switch source {
        case .campaign(let i): .campaign(i)
        case .random(let code): .random(code)
        }
        return SavedSession(source: savedSource, moves: state.history.map(\.direction), hintsUsed: hintsUsed,
                            elapsedSeconds: elapsed())
    }

    // MARK: - Reloj

    /// Tiempo de juego en segundos en el instante `date`.
    func elapsed(at date: Date = .now) -> TimeInterval {
        accumulated + (runningSince.map { date.timeIntervalSince($0) } ?? 0)
    }

    /// La app pasó a primer o segundo plano.
    func setAppActive(_ active: Bool) {
        appIsActive = active
        updateClock()
        if !active { saveNow() }
    }

    /// La pantalla de juego se cerró (menú, otro nivel…).
    func leaveScreen() {
        isOnScreen = false
        hintTask?.cancel()
        solvabilityTask?.cancel()
        updateClock()
        saveNow()
    }

    private func updateClock() {
        let shouldRun = moves > 0 && !solved && !isPaused && !showsVictory && isOnScreen && appIsActive
        if shouldRun, runningSince == nil {
            runningSince = .now
        } else if !shouldRun, let since = runningSince {
            accumulated += Date.now.timeIntervalSince(since)
            runningSince = nil
        }
    }

    private func saveNow() {
        guard !solved else { return }
        app?.saveSession(session(scene.game))
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
        let base = String(localized: "Zorro en la columna \(playerPosition.x), fila \(playerPosition.y). Cajas guardadas: \(boxesStored) de \(boxCount). Movimientos: \(moves).")
        guard stuckCount > 0 else { return base }
        return base + " " + String(localized: "Cajas atascadas: \(stuckCount).")
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
        runningSince = nil
        accumulated = 0
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
                app?.saveSession(session(scene.game))
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
        stuckCount = scene.stuckBoxes.count
        if !solved { isNewRecord = false }
        updateClock()
        checkSolvability(state)
        // Guardar para reanudar al volver a abrir la app (una partida resuelta ya no se reanuda).
        if solved {
            app?.clearSession()
        } else {
            app?.saveSession(session(state))
        }
    }

    // MARK: - ¿Sigue teniendo solución?

    /// Tras cada cambio en las cajas, el solucionador comprueba en segundo plano si el nivel
    /// todavía se puede resolver desde aquí. Si no, avisa (aunque ninguna caja esté en un
    /// fondo de saco evidente: por ejemplo, dos cajas que se estorban mutuamente).
    private func checkSolvability(_ state: GameState) {
        guard Preferences.warnStuck, !state.isSolved else {
            solvabilityTask?.cancel()
            checkedBoxes = nil
            isUnsolvable = false
            return
        }
        guard state.boxes != checkedBoxes else { return }
        checkedBoxes = state.boxes
        solvabilityTask?.cancel()
        if !scene.stuckBoxes.isEmpty {
            isUnsolvable = true
            return
        }
        let level = state.level
        solvabilityTask = Task {
            let result = await Self.solve(level)
            guard !Task.isCancelled, scene.game.boxes == level.boxes else { return }
            let unsolvable = result == .unsolvable
            if unsolvable && !isUnsolvable && stuckCount == 0 {
                let text = String(localized: "Este puzle ya no tiene solución desde aquí. Deshaz (Z) o reinicia (R).")
                banner = Banner(text: text)
                AccessibilityNotification.Announcement(text).post()
            }
            isUnsolvable = unsolvable
        }
    }

    /// Vuelve a comprobar (al cambiar el ajuste de avisos).
    func refreshWarnings() {
        checkedBoxes = nil
        scene.refreshStuck()
        checkSolvability(scene.game)
    }

    @concurrent
    private static func solve(_ level: Level) async -> SolverResult {
        Solver(maxStates: 300_000).solve(level, isCancelled: { Task.isCancelled })
    }

    /// Una caja acaba de quedar en un fondo de saco.
    private func didGetStuck(_ count: Int) {
        stuckCount = count
        let text = String(localized: "¡Ojo! Una caja quedó en un fondo de saco y ya no puede llegar a un destino. Deshaz (Z) o reinicia (R).")
        banner = Banner(text: text)
        AccessibilityNotification.Announcement(text).post()
    }

    private func didSolve() {
        updateClock()
        if let i = campaignIndex {
            isNewRecord = app?.completeCampaign(i, moves: moves, pushes: pushes, seconds: Int(elapsed().rounded())) ?? false
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
