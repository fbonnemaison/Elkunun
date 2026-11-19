// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkununCore

@Suite("Solucionador")
struct SolverTests {
    /// Niveles originales de prueba, de menor a mayor complejidad, con su mínimo de empujes.
    static let solvable: [(name: String, xsb: String, pushes: Int)] = [
        ("pasillo", "######\n#@$ .#\n######", 2),
        ("ya resuelto", "#####\n#@* #\n#####", 0),
        ("rodeo", """
            ######
            #    #
            # $  #
            #@ # #
            #  .##
            #####
            """, 3),
        ("dos cajas", """
            #######
            #     #
            # $.$ #
            #  @ .#
            #######
            """, 3),
        ("tres cajas", """
            ########
            #  .   #
            # $$ . #
            #@ #   #
            #  $ . #
            ########
            """, -1),
        ("almacén", """
              ######
            ###    #
            #   $# #
            # $.  .#
            #  .$  #
            ### @$.#
              #    #
              ######
            """, 6),
        ("dos zonas", """
            ########
            #.  #  #
            # $$  .#
            #  # $ #
            #. $  @#
            #  .#  #
            ########
            """, 11),
    ]

    @Test("Resuelve y la solución funciona al jugarla", arguments: solvable.map(\.name))
    func solvesAndReplays(name: String) throws {
        let entry = try #require(Self.solvable.first { $0.name == name })
        let level = try Level(xsb: entry.xsb)
        let solution = try #require(Solver().solve(level).solution, "«\(name)» debería tener solución")

        var game = GameState(level: level)
        for d in solution.moves {
            #expect(game.move(d) != .blocked, "Movimiento bloqueado en «\(name)»")
        }
        #expect(game.isSolved)
        #expect(game.pushCount == solution.pushCount)
        #expect(game.lurd == solution.lurd)
        if entry.pushes >= 0 {
            #expect(solution.pushCount == entry.pushes, "Empujes no óptimos en «\(name)»")
        }
    }

    @Test("Encuentra el mínimo de empujes")
    func optimalPushes() throws {
        // Lo óptimo son 2 empujes a la derecha y 1 hacia abajo.
        let level = try Level(xsb: """
            #######
            #     #
            #@$   #
            #   . #
            #######
            """)
        let solution = try #require(Solver().solve(level).solution)
        #expect(solution.pushCount == 3)
    }

    @Test("Caja en una esquina sin destino: sin solución")
    func cornerIsUnsolvable() throws {
        let level = try Level(xsb: """
            #####
            #$ .#
            #@  #
            #####
            """)
        #expect(Solver().solve(level) == .unsolvable)
    }

    @Test("Dos cajas alineadas en un pasillo: sin solución")
    func blockedCorridor() throws {
        let level = try Level(xsb: "#######\n#@$$..#\n#######")
        #expect(Solver().solve(level) == .unsolvable)
    }

    @Test("Dos salas unidas solo por cajas: sin solución (comprobado por fuerza bruta)")
    func twoRoomsUnsolvable() throws {
        let level = try Level(xsb: """
            #########
            #   #   #
            # $ $ $ #
            #.. # ..#
            # $ $@ .#
            #   #   #
            #########
            """)
        #expect(Solver.deadSquares(of: level.board).isDisjoint(with: level.boxes))
        #expect(Solver().solve(level) == .unsolvable)
    }

    @Test("Respeta el límite de posiciones")
    func limit() throws {
        let level = try Level(xsb: try #require(Self.solvable.first { $0.name == "dos cajas" }).xsb)
        #expect(Solver(maxStates: 2).solve(level) == .limitReached)
    }

    @Test("Se puede cancelar")
    func cancel() throws {
        let level = try Level(xsb: try #require(Self.solvable.first { $0.name == "dos cajas" }).xsb)
        #expect(Solver().solve(level, isCancelled: { true }) == .limitReached)
    }

    @Test("Casillas muertas: esquinas y bordes sin destino")
    func deadSquares() throws {
        let level = try Level(xsb: """
            ######
            #@   #
            # $. #
            #    #
            ######
            """)
        let dead = Solver.deadSquares(of: level.board)
        #expect(dead.contains(Position(x: 1, y: 1)))   // esquina
        #expect(dead.contains(Position(x: 4, y: 3)))   // esquina
        #expect(dead.contains(Position(x: 2, y: 1)))   // borde superior sin destino
        #expect(!dead.contains(Position(x: 2, y: 2)))  // centro
        #expect(!dead.contains(Position(x: 3, y: 2)))  // destino
    }

    @Test("Bloqueo 2×2: dos cajas contra un muro se descartan")
    func frozenSquare() throws {
        // Sin poda 2×2 el solucionador también acaba, pero la poda evita explorar ese callejón.
        let level = try Level(xsb: """
            #######
            #     #
            # $$  #
            #  @  #
            # ..  #
            #######
            """)
        let solution = try #require(Solver().solve(level).solution)
        #expect(solution.pushCount == 4)
    }
}
