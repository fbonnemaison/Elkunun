// © 2026 App-Zilla. Licencia MIT.

import Foundation
import Testing
@testable import ElkununCore

@Suite("Partida guardada")
struct SavedSessionTests {
    @Test("Guarda y recupera una partida de campaña en JSON")
    func campaignRoundTrip() throws {
        let session = SavedSession(source: .campaign(7), moves: [.up, .right, .down, .left], hintsUsed: 2,
                                   elapsedSeconds: 75.5)
        #expect(session.moves == "urdl")
        let data = try JSONEncoder().encode(session)
        #expect(try JSONDecoder().decode(SavedSession.self, from: data) == session)
    }

    @Test("Guarda y recupera una partida aleatoria con su código")
    func randomRoundTrip() throws {
        let code = LevelCode(difficulty: .hard, seed: 0xBEEF)
        let session = SavedSession(source: .random(code), moves: [.left])
        let data = try JSONEncoder().encode(session)
        #expect(String(decoding: data, as: UTF8.self).contains("3-0000BEEF"))
        #expect(try JSONDecoder().decode(SavedSession.self, from: data) == session)
    }

    @Test("Repite los movimientos y deja el nivel donde estaba")
    func replay() throws {
        let level = try Level(xsb: "#######\n#@$  .#\n#######")
        let session = SavedSession(source: .campaign(0), moves: [.right, .right])
        let game = try #require(session.replay(on: level))
        #expect(game.player == Position(x: 3, y: 1))
        #expect(game.pushCount == 2)
        #expect(game.moveCount == 2)
    }

    @Test("Descarta partidas con movimientos imposibles o texto dañado")
    func invalid() throws {
        let level = try Level(xsb: "#######\n#@$  .#\n#######")
        #expect(SavedSession(source: .campaign(0), moves: [.up]).replay(on: level) == nil)
        var broken = SavedSession(source: .campaign(0), moves: [])
        broken.moves = "rx"
        #expect(broken.directions == nil)
        let legacy = try JSONDecoder().decode(SavedSession.self, from: Data(#"{"campaign":3,"moves":"r"}"#.utf8))
        #expect(legacy.elapsedSeconds == 0)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SavedSession.self, from: Data(#"{"moves":"r"}"#.utf8))
        }
    }

    @Test("Las 60 soluciones de la campaña se pueden guardar y repetir")
    func campaignSolutions() throws {
        for (i, entry) in Campaign.entries.enumerated() {
            let moves = entry.solution.compactMap(Direction.init(lurd:))
            let game = try #require(SavedSession(source: .campaign(i), moves: moves).replay(on: entry.level()))
            #expect(game.isSolved)
        }
    }
}
