// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkununCore

@Suite("Aleatoriedad con semilla")
struct SeededRandomTests {
    @Test("SplitMix64 produce la secuencia de referencia (estabilidad entre versiones)")
    func reference() {
        var r = SeededRandom(seed: 0)
        #expect(r.next() == 0xE220_A839_7B1D_CDAF)
        #expect(r.next() == 0x6E78_9E6A_A1B9_65F4)
    }

    @Test("int(below:) se mantiene en rango")
    func range() {
        var r = SeededRandom(seed: 7)
        for bound in [1, 2, 3, 10, 1000] {
            for _ in 0..<200 {
                let v = r.int(below: bound)
                #expect(v >= 0 && v < bound)
            }
        }
    }
}

@Suite("Generador")
struct GeneratorTests {
    /// Comprueba que la solución guardada resuelve el nivel jugando de verdad.
    private func replay(_ level: Level, _ moves: [Direction]) -> GameState {
        var game = GameState(level: level)
        for d in moves { game.move(d) }
        return game
    }

    @Test("Misma semilla, mismo nivel")
    func deterministic() throws {
        let a = try LevelGenerator.generate(seed: 1234, settings: .preset(.medium))
        let b = try LevelGenerator.generate(seed: 1234, settings: .preset(.medium))
        #expect(a.level == b.level)
        #expect(a.solution == b.solution)
    }

    @Test("Semillas distintas dan niveles distintos")
    func differentSeeds() throws {
        let a = try LevelGenerator.generate(seed: 1, settings: .preset(.easy))
        let b = try LevelGenerator.generate(seed: 2, settings: .preset(.easy))
        #expect(a.level != b.level)
    }

    @Test("Niveles fáciles y medios: válidos, resolubles y dentro de los límites",
          arguments: [Difficulty.easy, .medium], UInt64(1)...8)
    func generated(difficulty: Difficulty, seed: UInt64) throws {
        let settings = GeneratorSettings.preset(difficulty)
        let g = try LevelGenerator.generate(seed: seed, settings: settings)
        #expect(g.level.boxes.count == settings.boxes)
        #expect(g.solution.pushCount >= settings.minPushes)
        if let max = settings.maxPushes { #expect(g.solution.pushCount <= max) }
        #expect(g.level.boxes.allSatisfy { !g.level.board.isGoal($0) }, "Ninguna caja empieza en su destino")
        #expect(replay(g.level, g.solution.moves).isSolved)
        // El borde exterior es siempre muro.
        let b = g.level.board
        for x in 0..<b.width {
            #expect(b.isWall(Position(x: x, y: 0)) && b.isWall(Position(x: x, y: b.height - 1)))
        }
    }

    @Test("Nivel difícil")
    func hard() throws {
        let settings = GeneratorSettings.preset(.hard)
        let g = try LevelGenerator.generate(seed: 3, settings: settings)
        #expect(g.level.boxes.count == 4)
        #expect(g.solution.pushCount >= settings.minPushes)
        #expect(replay(g.level, g.solution.moves).isSolved)
    }

    @Test("Se puede cancelar")
    func cancel() {
        #expect(throws: GeneratorError.cancelled) {
            try LevelGenerator.generate(seed: 1, settings: .preset(.hard), isCancelled: { true })
        }
    }

    @Test("Generación asíncrona")
    func async() async throws {
        let g = try await LevelGenerator.generate(seed: 5, settings: .preset(.easy))
        let sync = try LevelGenerator.generate(seed: 5, settings: .preset(.easy), isCancelled: { false })
        #expect(g.level == sync.level)
    }

    @Test("Cambios de caja en la solución")
    func boxChanges() throws {
        let level = try Level(xsb: """
            #######
            #.$@$.#
            #######
            """)
        let solution = try #require(Solver().solve(level).solution)
        #expect(LevelGenerator.boxChanges(level, solution) == 1)
    }
}

@Suite("Códigos de nivel")
struct LevelCodeTests {
    @Test("Formato y lectura")
    func roundTrip() throws {
        let code = LevelCode(difficulty: .medium, seed: 0x9F3A_0C1D)
        #expect(code.description == "2-9F3A0C1D")
        #expect(LevelCode("2-9F3A0C1D") == code)
        #expect(LevelCode(" 2 9f3a0c1d ") == code)
        #expect(LevelCode(difficulty: .easy, seed: 0xAB).description == "1-000000AB")
    }

    @Test("Rechaza códigos inválidos", arguments: ["", "4-00000000", "2-12345", "2-GGGGGGGG", "x-9F3A0C1D", "2-9F3A0C1D0"])
    func invalid(text: String) {
        #expect(LevelCode(text) == nil)
    }

    @Test("La dificultad cambia el nivel aunque la semilla sea igual")
    func difficultyChangesSeed() {
        let a = LevelCode(difficulty: .easy, seed: 1)
        let b = LevelCode(difficulty: .medium, seed: 1)
        #expect(a.generatorSeed != b.generatorSeed)
    }

    @Test("Un código genera siempre el mismo nivel")
    func generates() throws {
        let code = try #require(LevelCode("1-0000BEEF"))
        #expect(try code.generate().level == (try code.generate().level))
    }
}

@Suite("Campaña")
struct CampaignTests {
    @Test("Tiene 60 niveles")
    func count() {
        #expect(Campaign.entries.count == Campaign.levelCount)
        #expect(Campaign.levelCount == 60)
    }

    @Test("Cada nivel es válido y su solución guardada lo resuelve con los empujes indicados",
          arguments: 0..<60)
    func solutions(index: Int) throws {
        let entry = Campaign.entries[index]
        let level = try Level(xsb: entry.xsb)
        var game = GameState(level: level)
        let moves = entry.solution.map { c -> Direction in
            switch c.lowercased() {
            case "l": .left
            case "r": .right
            case "u": .up
            default: .down
            }
        }
        for d in moves { #expect(game.move(d) != .blocked) }
        #expect(game.isSolved)
        #expect(game.pushCount == entry.optimalPushes)
        #expect(moves.count == entry.solutionMoves)
    }

    @Test("La dificultad no baja: empiezan con 1 caja y terminan con 4")
    func curve() {
        #expect(Campaign.level(0).boxes.count == 1)
        #expect(Campaign.level(59).boxes.count == 4)
        let pushes = Campaign.entries.map(\.optimalPushes)
        #expect(pushes.first! < pushes.last!)
    }

    @Test("Los primeros niveles tienen el mínimo de empujes que indica el archivo", arguments: 0..<10)
    func optimal(index: Int) throws {
        let entry = Campaign.entries[index]
        let solution = try #require(Solver().solve(entry.level()).solution)
        #expect(solution.pushCount == entry.optimalPushes)
    }
}
