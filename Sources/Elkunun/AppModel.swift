// © 2026 App-Zilla. Licencia MIT.

import ElkununCore
import Foundation
import Observation
import SwiftUI

/// Estado global de la app: pantalla actual, progreso de la campaña y generación de niveles.
@MainActor
@Observable
final class AppModel {
    enum Screen {
        case menu
        case campaign
        case random
        case credits
        case scores
        case game(GameModel)
    }

    var screen: Screen = .menu

    /// Barrido entre pantallas: 0 descubierto, 1 cubierto, 2 terminado (vuelve a 0 sin animar).
    private(set) var sweepProgress: Double = 0
    /// Cambia en cada barrido, para que el borde irregular sea distinto cada vez.
    private(set) var sweepSeed: UInt64 = 0
    private var sweepTask: Task<Void, Never>?
    /// Duración de cada mitad del barrido (cubrir y descubrir).
    static let sweepHalf: TimeInterval = 0.38
    private(set) var progress: CampaignProgress
    /// Última partida sin terminar (se reanuda al abrir la app o con «Continuar»).
    private(set) var savedSession: SavedSession?

    /// Generación de un nivel aleatorio en curso.
    private(set) var isGenerating = false
    var generationError: String?
    private var generationTask: Task<Void, Never>?

    /// Última dificultad elegida en el modo libre.
    var lastDifficulty: Difficulty = .easy

    init() {
        progress = Self.loadProgress()
        savedSession = Self.loadSession()
        // Al abrir se muestra la pantalla de inicio (continuar, empezar de cero, puntajes).
        if let start = Self.startLevelArgument() {
            openCampaign(start)
        }
    }

    // MARK: - Navegación

    func showMenu() {
        cancelGeneration()
        screen = .menu
    }

    func showCampaign() { screen = .campaign }
    func showRandom() { screen = .random }
    func showCredits() { screen = .credits }
    func showScores() { screen = .scores }

    /// Empieza la campaña desde el nivel 1, descartando la partida en curso.
    /// Las mejores marcas se conservan.
    func startOver() {
        clearSession()
        openCampaign(0)
    }

    /// Hay algo que «empezar de cero»: una partida en curso o niveles completados.
    var hasPlayed: Bool { savedSession != nil || progress.completedCount > 0 }

    /// Reanuda la partida guardada o, si no hay, el siguiente nivel de la campaña.
    func continuePlaying() {
        if let savedSession {
            resume(savedSession)
        } else {
            playCampaign(progress.nextLevel)
        }
    }

    /// Texto del botón «Continuar» del menú.
    var continueTitle: String {
        savedSession == nil
            ? String(localized: "Continuar · nivel \(progress.nextLevel + 1)")
            : String(localized: "Continuar la última partida")
    }

    /// Detalle de la partida guardada (nivel, movimientos y tiempo).
    var continueDetail: String? {
        guard let session = savedSession else { return nil }
        let level = switch session.source {
        case .campaign(let i): String(localized: "Nivel \(i + 1) de \(Campaign.levelCount)")
        case .random(let code): String(localized: "Nivel aleatorio \(code.description)")
        }
        let moves = session.moves.count
        return String(localized: "\(level) · \(moves) movimientos · \(formatTime(session.elapsedSeconds))")
    }

    var canContinue: Bool { savedSession != nil || progress.completedCount > 0 }

    func resume(_ session: SavedSession) {
        switch session.source {
        case .campaign(let index):
            openCampaign(index, resume: session)
        case .random(let code):
            playRandom(code, resume: session)
        }
    }

    func playCampaign(_ index: Int) {
        guard progress.isUnlocked(index) else { return }
        openCampaign(index)
    }

    private func openCampaign(_ index: Int, resume: SavedSession? = nil) {
        guard (0..<Campaign.levelCount).contains(index) else { return }
        let entry = Campaign.entries[index]
        showGame {
            GameModel(source: .campaign(index), level: entry.level(),
                      optimalPushes: entry.optimalPushes, app: self, resume: resume)
        }
    }

    /// Abre un nivel con un barrido irregular de izquierda a derecha: primero tapa la pantalla
    /// actual, cambia de pantalla y luego la destapa. Sin barrido con «Reducir movimiento».
    /// El nivel se crea cuando la pantalla ya está tapada, para que su reloj no corra antes.
    private func showGame(_ make: @escaping () -> GameModel) {
        sweepTask?.cancel()
        guard !Preferences.reduceMotion else {
            sweepProgress = 0
            screen = .game(make())
            return
        }
        // Si un barrido anterior se estaba destapando, empieza de nuevo desde la izquierda.
        if sweepProgress != 1 { sweepProgress = 0 }
        sweepSeed &+= 1
        withAnimation(.easeIn(duration: Self.sweepHalf)) { sweepProgress = 1 }
        sweepTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.sweepHalf))
            guard let self, !Task.isCancelled else { return }
            screen = .game(make())
            withAnimation(.easeOut(duration: Self.sweepHalf)) { sweepProgress = 2 }
            try? await Task.sleep(for: .seconds(Self.sweepHalf))
            guard !Task.isCancelled else { return }
            sweepProgress = 0
        }
    }

    func playRandom(_ code: LevelCode, resume: SavedSession? = nil) {
        // Solo dificultades desbloqueadas en la campaña (una partida ya empezada sí se reanuda).
        guard resume != nil || progress.isUnlocked(code.difficulty) else {
            generationError = Self.lockedMessage(code.difficulty)
            screen = .random
            return
        }
        cancelGeneration()
        lastDifficulty = code.difficulty
        isGenerating = true
        generationError = nil
        generationTask = Task {
            do {
                let generated = try await code.generate()
                guard !Task.isCancelled else { return }
                isGenerating = false
                showGame {
                    GameModel(source: .random(code), level: generated.level,
                              optimalPushes: generated.solution.pushCount, app: self, resume: resume)
                }
            } catch {
                isGenerating = false
                if case .noLevelFound? = error as? GeneratorError {
                    generationError = String(localized: "No se pudo crear un nivel con ese código. Prueba otro.")
                }
            }
        }
    }

    func playNewRandom(_ difficulty: Difficulty) {
        // Si la dificultad pedida aún está bloqueada (p. ej. con ⌘N), usar la más alta disponible.
        let allowed = progress.isUnlocked(difficulty)
            ? difficulty
            : Difficulty.allCases.last(where: progress.isUnlocked) ?? .easy
        playRandom(.random(allowed))
    }

    /// Mensaje para una dificultad aún bloqueada.
    static func lockedMessage(_ difficulty: Difficulty) -> String {
        let group = difficulty.requiredCampaignGroup
        return String(localized: "Esa dificultad se desbloquea al completar los niveles 1–\(group * Campaign.levelsPerGroup) de la campaña.")
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
    }

    // MARK: - Progreso

    /// Registra un nivel de campaña completado. Devuelve `true` si es nueva mejor marca.
    @discardableResult
    func completeCampaign(_ index: Int, moves: Int, pushes: Int, seconds: Int) -> Bool {
        let improved = progress.complete(index, moves: moves, pushes: pushes, seconds: seconds)
        saveProgress()
        return improved
    }

    func resetProgress() {
        progress.reset()
        saveProgress()
        clearSession()
    }

    // MARK: - Partida en curso

    func saveSession(_ session: SavedSession) {
        guard session != savedSession else { return }
        savedSession = session
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: PreferenceKey.savedSession)
        }
    }

    func clearSession() {
        guard savedSession != nil else { return }
        savedSession = nil
        UserDefaults.standard.removeObject(forKey: PreferenceKey.savedSession)
    }

    private static func loadSession() -> SavedSession? {
        guard let data = UserDefaults.standard.data(forKey: PreferenceKey.savedSession) else { return nil }
        return try? JSONDecoder().decode(SavedSession.self, from: data)
    }

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: PreferenceKey.campaignProgress)
        }
    }

    private static func loadProgress() -> CampaignProgress {
        guard let data = UserDefaults.standard.data(forKey: PreferenceKey.campaignProgress),
              let progress = try? JSONDecoder().decode(CampaignProgress.self, from: data) else {
            return CampaignProgress()
        }
        return progress
    }

    /// Para desarrollo: `-startLevel N` abre directamente el nivel N (1…60), aunque esté bloqueado.
    private static func startLevelArgument() -> Int? {
        let n = UserDefaults.standard.integer(forKey: "startLevel")
        return (1...Campaign.levelCount).contains(n) ? n - 1 : nil
    }
}
