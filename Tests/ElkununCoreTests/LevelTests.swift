// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkununCore

@Suite("Level y formato XSB")
struct LevelTests {
    @Test("Lee muros, suelo, destinos, cajas y jugador")
    func parse() throws {
        let level = try Level(xsb: """
            #####
            #@$.#
            #####
            """)
        #expect(level.board.width == 5)
        #expect(level.board.height == 3)
        #expect(level.player == Position(x: 1, y: 1))
        #expect(level.boxes == [Position(x: 2, y: 1)])
        #expect(level.board.goals == [Position(x: 3, y: 1)])
        #expect(level.board.isWall(Position(x: 0, y: 0)))
        #expect(!level.isSolved)
    }

    @Test("Caja sobre destino y jugador sobre destino")
    func goalVariants() throws {
        let level = try Level(xsb: """
            ######
            #+*$ #
            ######
            """)
        #expect(level.board.isGoal(level.player))
        #expect(level.boxes.count == 2)
        #expect(level.board.goals.count == 2) // + y *
        #expect(level.board.isGoal(Position(x: 2, y: 1)))
    }

    @Test("Ida y vuelta XSB conserva el nivel", arguments: [
        "#####\n#@$.#\n#####",
        "  ####\n###  #\n#  *+#\n# $.$#\n#    #\n######",
    ])
    func roundTrip(xsb: String) throws {
        let level = try Level(xsb: xsb)
        #expect(level.xsb == xsb)
        #expect(try Level(xsb: level.xsb) == level)
    }

    @Test("Acepta - y _ como suelo y rellena filas cortas")
    func floorAliasesAndPadding() throws {
        let level = try Level(xsb: "\n#####\n#@$.#\n#-_#\n####\n\n")
        #expect(level.board.width == 5)
        #expect(level.board.height == 4)
        #expect(level.board[Position(x: 4, y: 2)] == .floor)
        #expect(level.board[Position(x: 1, y: 2)] == .floor)
    }

    @Test("Fuera del tablero se considera muro")
    func outsideIsWall() throws {
        let level = try Level(xsb: "#@$.#")
        #expect(level.board.isWall(Position(x: -1, y: 0)))
        #expect(level.board.isWall(Position(x: 0, y: 5)))
    }

    @Test("Errores de validación")
    func errors() {
        #expect(throws: LevelError.empty) { try Level(xsb: "  \n\n") }
        #expect(throws: LevelError.missingPlayer) { try Level(xsb: "#$.#") }
        #expect(throws: LevelError.multiplePlayers) { try Level(xsb: "#@@$.#") }
        #expect(throws: LevelError.noBoxes) { try Level(xsb: "#@ #") }
        #expect(throws: LevelError.boxGoalMismatch(boxes: 2, goals: 1)) { try Level(xsb: "#@$$.#") }
        #expect(throws: LevelError.invalidCharacter("x", line: 2, column: 3)) {
            try Level(xsb: "#####\n#@x.#\n#####")
        }
    }

    @Test("Rechaza jugador o cajas sobre muros al construir a mano")
    func overlapping() throws {
        let board = Board(width: 3, height: 1, tiles: [.wall, .floor, .goal])
        #expect(throws: LevelError.overlapping) {
            try Level(board: board, player: Position(x: 0, y: 0), boxes: [Position(x: 2, y: 0)])
        }
        #expect(throws: LevelError.overlapping) {
            try Level(board: board, player: Position(x: 2, y: 0), boxes: [Position(x: 2, y: 0)])
        }
    }
}
