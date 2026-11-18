// © 2026 App-Zilla. Licencia MIT.

import ElkunufeCore
import Foundation
import Observation

/// Estado global de la app: pantalla actual, progreso de la campaña y generación de niveles.
@MainActor
@Observable
final class AppModel {
    enum Screen {
        case menu
        case campaign
        case random
        case credits
        case game(GameModel)
    }

    var screen: Screen = .menu
    private(set) var progress: CampaignProgress

    /// Generación de un nivel aleatorio en curso.
    private(set) var isGenerating = false
    var generationError: String?
    private var generationTask: Task<Void, Never>?

    /// Última dificultad elegida en el modo libre.
    var lastDifficulty: Difficulty = .easy

    init() {
        progress = Self.loadProgress()
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

    func continueCampaign() {
        playCampaign(progress.nextLevel)
    }

    func playCampaign(_ index: Int) {
        guard progress.isUnlocked(index) else { return }
        openCampaign(index)
    }

    private func openCampaign(_ index: Int) {
        let entry = Campaign.entries[index]
        screen = .game(GameModel(source: .campaign(index), level: entry.level(),
                                 optimalPushes: entry.optimalPushes, app: self))
    }

    func playRandom(_ code: LevelCode) {
        cancelGeneration()
        lastDifficulty = code.difficulty
        isGenerating = true
        generationError = nil
        generationTask = Task {
            do {
                let generated = try await code.generate()
                guard !Task.isCancelled else { return }
                isGenerating = false
                screen = .game(GameModel(source: .random(code), level: generated.level,
                                         optimalPushes: generated.solution.pushCount, app: self))
            } catch {
                isGenerating = false
                if case .noLevelFound? = error as? GeneratorError {
                    generationError = String(localized: "No se pudo crear un nivel con ese código. Prueba otro.")
                }
            }
        }
    }

    func playNewRandom(_ difficulty: Difficulty) {
        playRandom(.random(difficulty))
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
    }

    // MARK: - Progreso

    /// Registra un nivel de campaña completado. Devuelve `true` si es nueva mejor marca.
    @discardableResult
    func completeCampaign(_ index: Int, moves: Int, pushes: Int) -> Bool {
        let improved = progress.complete(index, moves: moves, pushes: pushes)
        saveProgress()
        return improved
    }

    func resetProgress() {
        progress.reset()
        saveProgress()
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
