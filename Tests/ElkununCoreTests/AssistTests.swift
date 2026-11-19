// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkununCore

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

@Suite("Cajas atascadas")
struct StuckBoxTests {
    private func game(_ xsb: String) throws -> GameState {
        GameState(level: try Level(xsb: xsb))
    }

    @Test("Caja en una esquina sin destino")
    func corner() throws {
        let g = try game("""
            ######
            #$  .#
            # @  #
            ######
            """)
        #expect(g.stuckBoxes() == [Position(x: 1, y: 1)])
    }

    @Test("Caja pegada a una pared sin destino en esa pared")
    func wallWithoutGoal() throws {
        let g = try game("""
            #######
            #  $  #
            #  @  #
            #   . #
            #######
            """)
        #expect(g.stuckBoxes() == [Position(x: 3, y: 1)])
    }

    @Test("Una caja libre en el centro no está atascada")
    func free() throws {
        let g = try game("""
            ######
            #    #
            # $@ #
            #  . #
            ######
            """)
        #expect(g.stuckBoxes().isEmpty)
    }

    @Test("Una caja sobre su destino nunca se marca")
    func onGoal() throws {
        let g = try game("""
            #####
            #*  #
            # @ #
            #####
            """)
        #expect(g.stuckBoxes().isEmpty)
    }

    @Test("Dos cajas juntas contra una pared se bloquean entre sí")
    func frozenPair() throws {
        let g = try game("""
            #######
            #     #
            # $$  #
            #  @  #
            # ..  #
            #######
            """)
        // Sueltas en el centro: no.
        #expect(g.stuckBoxes().isEmpty)
        let h = try game("""
            #######
            # $$  #
            #  @  #
            #  .. #
            #     #
            #######
            """)
        // Pegadas a la pared de arriba (que no tiene destinos): las dos.
        #expect(h.stuckBoxes() == [Position(x: 2, y: 1), Position(x: 3, y: 1)])
    }

    @Test("Bloque 2×2 de cajas en mitad de la sala")
    func frozenSquare() throws {
        let g = try game("""
            ########
            #      #
            # $$   #
            # $$ @ #
            #  ....#
            ########
            """)
        #expect(g.stuckBoxes().count == 4)
    }

    @Test("Coincide con el solucionador: si hay cajas atascadas, no hay solución")
    func agreesWithSolver() throws {
        var rng = SeededRandom(seed: 5)
        for i in 0..<20 {
            var g = GameState(level: Campaign.level(i))
            for _ in 0..<30 { g.move(Direction.allCases[rng.int(below: 4)]) }
            if !g.stuckBoxes().isEmpty {
                #expect(Solver().solve(g.level) == .unsolvable, "Nivel \(i + 1)")
            }
        }
    }
}
