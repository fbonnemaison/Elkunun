// © 2026 App-Zilla. Licencia MIT.

import Foundation
import Testing
@testable import ElkununCore

@Suite("Progreso de campaña")
struct CampaignProgressTests {
    @Test("Al empezar solo están disponibles los niveles 1–10")
    func initialUnlock() {
        let p = CampaignProgress()
        #expect((0..<10).allSatisfy(p.isUnlocked))
        #expect(!(10..<60).contains(where: p.isUnlocked))
        #expect(!p.isUnlocked(-1) && !p.isUnlocked(60))
        #expect(p.unlockedGroupCount == 1)
        #expect(p.nextLevel == 0)
    }

    @Test("Completar los 10 de un grupo desbloquea el siguiente grupo completo")
    func unlockByGroup() {
        var p = CampaignProgress()
        for i in 0..<9 { p.complete(i, moves: 10, pushes: 5) }
        #expect(!p.isUnlocked(10), "Falta el nivel 10")
        p.complete(9, moves: 10, pushes: 5)
        #expect((10..<20).allSatisfy(p.isUnlocked))
        #expect(!p.isUnlocked(20))
        #expect(p.unlockedGroupCount == 2)
    }

    @Test("Un nivel ya completado sigue disponible aunque su grupo no lo esté")
    func completedStaysUnlocked() {
        var p = CampaignProgress()
        p.complete(25, moves: 10, pushes: 5)  // progreso guardado con la regla antigua
        #expect(p.isUnlocked(25))
        #expect(!p.isUnlocked(24))
    }

    @Test("Las dificultades del modo aleatorio siguen a la campaña")
    func randomDifficulties() {
        var p = CampaignProgress()
        #expect(p.isUnlocked(.easy) && !p.isUnlocked(.medium) && !p.isUnlocked(.hard))
        for i in 0..<20 { p.complete(i, moves: 10, pushes: 5) }
        #expect(p.isUnlocked(.medium) && !p.isUnlocked(.hard))
        for i in 20..<40 { p.complete(i, moves: 10, pushes: 5) }
        #expect(p.isUnlocked(.hard))
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

    @Test("El mejor tiempo se guarda aparte de la mejor marca")
    func bestTime() {
        var p = CampaignProgress()
        p.complete(0, moves: 10, pushes: 5, seconds: 90)
        p.complete(0, moves: 20, pushes: 9, seconds: 40)   // peor marca, mejor tiempo
        #expect(p.records[0] == .init(bestMoves: 10, bestPushes: 5, bestSeconds: 40))
        p.complete(0, moves: 9, pushes: 5, seconds: 60)    // mejor marca, peor tiempo
        #expect(p.records[0] == .init(bestMoves: 9, bestPushes: 5, bestSeconds: 40))
        p.complete(1, moves: 9, pushes: 5, seconds: 15)
        #expect(p.totalBestSeconds == 55)
    }

    @Test("Lee progresos guardados antes de que existiera el reloj")
    func legacyDecoding() throws {
        let json = #"{"records":{"0":{"bestMoves":10,"bestPushes":5}}}"#
        let p = try JSONDecoder().decode(CampaignProgress.self, from: Data(json.utf8))
        #expect(p.records[0] == .init(bestMoves: 10, bestPushes: 5, bestSeconds: nil))
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
