// © 2026 App-Zilla. Licencia MIT.

import ElkunufeCore
import Observation

/// Estado observable de la partida para SwiftUI. La escena aplica las reglas y anima;
/// este modelo refleja contadores y progreso.
@MainActor
@Observable
final class GameModel {
    let scene: BoardScene
    private(set) var levelIndex = 0
    private(set) var moves = 0
    private(set) var pushes = 0
    private(set) var solved = false
    private(set) var canUndo = false

    var levelCount: Int { Campaign.levelCount }
    var optimalPushes: Int { Campaign.entries[levelIndex].optimalPushes }
    var hasPrevious: Bool { levelIndex > 0 }
    var hasNext: Bool { levelIndex < levelCount - 1 }

    init(levelIndex: Int = 0) {
        self.levelIndex = levelIndex
        scene = BoardScene(level: Campaign.level(levelIndex))
        scene.onChange = { [weak self] state in self?.update(state) }
    }

    func load(_ index: Int) {
        guard (0..<levelCount).contains(index) else { return }
        levelIndex = index
        scene.load(Campaign.level(index))
    }

    func next() { load(levelIndex + 1) }
    func previous() { load(levelIndex - 1) }
    func move(_ direction: Direction) { scene.move(direction) }
    func undo() { scene.undo() }
    func redo() { scene.redo() }
    func restart() { scene.restart() }

    private func update(_ state: GameState) {
        moves = state.moveCount
        pushes = state.pushCount
        solved = state.isSolved
        canUndo = !state.history.isEmpty
    }
}
