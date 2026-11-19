// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkununCore

@Suite("Reglas del juego")
struct GameStateTests {
    /// Pasillo de una fila: jugador, caja y destino.
    static let corridor = "######\n#@$ .#\n######"

    private func game(_ xsb: String) throws -> GameState {
        GameState(level: try Level(xsb: xsb))
    }

    @Test("Caminar por el suelo")
    func walk() throws {
        var g = try game("#####\n#@  #\n# $.#\n#####")
        #expect(doMove(&g, .right) == .moved)
        #expect(g.player == Position(x: 2, y: 1))
        #expect(g.moveCount == 1)
        #expect(g.pushCount == 0)
    }

    @Test("Los muros bloquean y no cuentan como movimiento")
    func wallBlocks() throws {
        var g = try game(Self.corridor)
        #expect(doMove(&g, .up) == .blocked)
        #expect(doMove(&g, .left) == .blocked)
        #expect(g.player == Position(x: 1, y: 1))
        #expect(g.moveCount == 0)
    }

    @Test("Empujar una caja")
    func push() throws {
        var g = try game(Self.corridor)
        #expect(doMove(&g, .right) == .pushed)
        #expect(g.player == Position(x: 2, y: 1))
        #expect(g.boxes == [Position(x: 3, y: 1)])
        #expect(g.pushCount == 1)
    }

    @Test("Solo empujar: alejarse de una caja no la arrastra")
    func noPulling() throws {
        var g = try game("######\n# @$.#\n######")
        #expect(doMove(&g, .left) == .moved)
        #expect(g.boxes == [Position(x: 3, y: 1)])
    }

    @Test("No se puede empujar una caja contra un muro")
    func boxAgainstWall() throws {
        var g = try game("#####\n#@ $#\n#.  #\n#####")
        #expect(doMove(&g, .right) == .moved)
        #expect(doMove(&g, .right) == .blocked)
        #expect(g.boxes == [Position(x: 3, y: 1)])
    }

    @Test("Una caja a la vez: no se empujan dos cajas alineadas")
    func twoBoxes() throws {
        var g = try game("#######\n#@$$..#\n#######")
        #expect(doMove(&g, .right) == .blocked)
        #expect(g.boxes == [Position(x: 2, y: 1), Position(x: 3, y: 1)])
    }

    @Test("Se gana con todas las cajas en destino; después no se mueve")
    func win() throws {
        var g = try game(Self.corridor)
        g.move(.right)
        #expect(!g.isSolved)
        g.move(.right)
        #expect(g.isSolved)
        #expect(g.lurd == "RR")
        #expect(doMove(&g, .left) == .blocked)
    }

    @Test("Varias cajas: hace falta colocarlas todas")
    func multipleBoxes() throws {
        var g = try game("""
            #######
            #.$@$.#
            #######
            """)
        g.move(.left)
        #expect(!g.isSolved)
        g.move(.right)
        g.move(.right)
        #expect(g.isSolved)
        #expect(g.lurd == "LrR")
    }

    @Test("Deshacer un paso y un empuje")
    func undo() throws {
        var g = try game("#######\n#@ $ .#\n#######")
        g.move(.right)
        g.move(.right)
        #expect(g.boxes == [Position(x: 4, y: 1)])

        #expect(doUndo(&g))
        #expect(g.player == Position(x: 2, y: 1))
        #expect(g.boxes == [Position(x: 3, y: 1)])
        #expect(g.pushCount == 0)

        #expect(doUndo(&g))
        #expect(g.player == Position(x: 1, y: 1))
        #expect(g.moveCount == 0)
        #expect(!doUndo(&g))
    }

    @Test("Deshacer después de ganar vuelve a permitir jugar")
    func undoAfterWin() throws {
        var g = try game(Self.corridor)
        g.move(.right)
        g.move(.right)
        #expect(g.isSolved)
        g.undo()
        #expect(!g.isSolved)
        #expect(doMove(&g, .left) == .moved)
    }

    @Test("Rehacer y que un movimiento nuevo borre lo que había para rehacer")
    func redo() throws {
        var g = try game("#######\n#@ $ .#\n# #####\n###")
        g.move(.right)
        g.move(.right)
        g.undo()
        g.undo()
        #expect(doRedo(&g))
        #expect(g.player == Position(x: 2, y: 1))
        #expect(doRedo(&g))
        #expect(g.pushCount == 1)
        #expect(!doRedo(&g))

        g.undo()
        g.undo()
        g.move(.down)
        #expect(g.redoStack.isEmpty)
        #expect(!doRedo(&g))
    }

    @Test("Reiniciar vuelve al estado inicial")
    func restart() throws {
        var g = try game(Self.corridor)
        g.move(.right)
        g.restart()
        #expect(g.level == g.initial)
        #expect(g.moveCount == 0)
        #expect(g.pushCount == 0)
        #expect(!doUndo(&g))
    }

    @Test("outcome(of:) predice sin cambiar el estado")
    func outcomeIsPure() throws {
        let g = try game(Self.corridor)
        #expect(g.outcome(of: .right) == .pushed)
        #expect(g.outcome(of: .up) == .blocked)
        #expect(g.moveCount == 0)
    }

    @Test("Deshacer todo tras una partida aleatoria devuelve el nivel inicial")
    func randomUndo() throws {
        var g = try game("""
            ########
            #  .   #
            # $$ . #
            #@ #   #
            #  $ . #
            ########
            """)
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            g.move(Direction.allCases.randomElement(using: &rng)!)
        }
        while g.undo() {}
        #expect(g.level == g.initial)
        #expect(g.pushCount == 0)
    }
}

// #expect no admite llamadas `mutating` dentro de la macro; estas funciones las envuelven.
private func doMove(_ g: inout GameState, _ d: Direction) -> MoveResult { g.move(d) }
private func doUndo(_ g: inout GameState) -> Bool { g.undo() }
private func doRedo(_ g: inout GameState) -> Bool { g.redo() }
