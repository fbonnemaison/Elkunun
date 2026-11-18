// © 2026 App-Zilla. Licencia MIT.

import Foundation
import Testing
@testable import ElkunufeCore

@Suite("Progreso de campaña")
struct CampaignProgressTests {
    @Test("Al empezar se pueden jugar los 3 primeros niveles")
    func initialUnlock() {
        let p = CampaignProgress()
        #expect(p.isUnlocked(0) && p.isUnlocked(1) && p.isUnlocked(2))
        #expect(!p.isUnlocked(3))
        #expect(!p.isUnlocked(-1) && !p.isUnlocked(60))
        #expect(p.nextLevel == 0)
    }

    @Test("Completar un nivel desbloquea los siguientes")
    func unlockAdvances() {
        var p = CampaignProgress()
        p.complete(4, moves: 10, pushes: 5)
        #expect(p.isUnlocked(7))
        #expect(!p.isUnlocked(8))
        #expect(p.nextLevel == 0)
    }

    @Test("La marca solo mejora con menos empujes, o mismos empujes y menos movimientos")
    func records() {
        var p = CampaignProgress()
        #expect(complete(&p, 0, moves: 10, pushes: 5))
        #expect(!complete(&p, 0, moves: 12, pushes: 5))
        #expect(!complete(&p, 0, moves: 8, pushes: 6))
        #expect(complete(&p, 0, moves: 9, pushes: 5))
        #expect(p.records[0] == .init(bestMoves: 9, bestPushes: 5))
        #expect(complete(&p, 0, moves: 11, pushes: 4))
        #expect(p.records[0] == .init(bestMoves: 9, bestPushes: 4))
    }

    @Test("Óptimo cuando se igualan los empujes mínimos")
    func optimal() {
        var p = CampaignProgress()
        let best = Campaign.entries[0].optimalPushes
        p.complete(0, moves: 50, pushes: best + 1)
        #expect(!p.isOptimal(0))
        p.complete(0, moves: 50, pushes: best)
        #expect(p.isOptimal(0))
    }

    @Test("Se guarda y se recupera en JSON")
    func codable() throws {
        var p = CampaignProgress()
        p.complete(2, moves: 30, pushes: 12)
        let data = try JSONEncoder().encode(p)
        #expect(try JSONDecoder().decode(CampaignProgress.self, from: data) == p)
    }
}

// #expect no admite llamadas `mutating` dentro de la macro.
private func complete(_ p: inout CampaignProgress, _ index: Int, moves: Int, pushes: Int) -> Bool {
    p.complete(index, moves: moves, pushes: pushes)
}
