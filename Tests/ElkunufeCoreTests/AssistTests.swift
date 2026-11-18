// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkunufeCore

@Suite("Ayudas: caminar y pistas")
struct AssistTests {
    private func game(_ xsb: String) throws -> GameState {
        GameState(level: try Level(xsb: xsb))
    }

    @Test("Camino más corto rodeando muros y cajas")
    func path() throws {
        let g = try game("""
            ######
            #@ # #
            #  $ #
            #   .#
            ######
            """)
        let route = try #require(g.path(to: Position(x: 4, y: 2)))
        #expect(route.count == 6)
        var copy = g
        for d in route {
            let result = copy.move(d)
            #expect(result == .moved)
        }
        #expect(copy.player == Position(x: 4, y: 2))
        #expect(copy.boxes == g.boxes)
    }

    @Test("Sin camino a muros, cajas o zonas cerradas")
    func noPath() throws {
        let g = try game("#######\n#@$ #.#\n#######")
        #expect(g.path(to: Position(x: 0, y: 0)) == nil)
        #expect(g.path(to: Position(x: 2, y: 1)) == nil)
        #expect(g.path(to: Position(x: 3, y: 1)) == nil)
        #expect(g.path(to: g.player) == [])
    }

    @Test("La pista indica el siguiente empuje")
    func hint() throws {
        let g = try game("######\n#@$ .#\n######")
        #expect(g.hint() == .push(box: Position(x: 2, y: 1), direction: .right, walk: [], remainingPushes: 2))
    }

    @Test("La pista incluye el camino hasta la caja")
    func hintWithWalk() throws {
        let g = try game("""
            ######
            #@   #
            # $  #
            #  . #
            ######
            """)
        guard case .push(let box, _, let walk, _) = g.hint() else {
            Issue.record("Debería haber pista")
            return
        }
        #expect(box == Position(x: 2, y: 2))
        #expect(!walk.isEmpty)
    }

    @Test("La pista avisa cuando ya no hay solución")
    func stuck() throws {
        var g = try game("""
            #####
            #   #
            # $ #
            #@ .#
            #####
            """)
        g.move(.right)
        g.move(.up)  // empuja la caja contra la pared de arriba
        #expect(g.hint() == .stuck)
    }

    @Test("Nivel resuelto")
    func solved() throws {
        var g = try game("#####\n#@$.#\n#####")
        g.move(.right)
        #expect(g.hint() == .solved)
    }
}
