// © 2026 App-Zilla. Licencia MIT.

/// Nivel de dificultad del modo libre.
public enum Difficulty: Int, CaseIterable, Codable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3

    /// Grupo de la campaña (0…5) que hay que tener desbloqueado para jugar esta dificultad en
    /// modo aleatorio: fácil (2 cajas) desde el inicio, media (3 cajas) con los niveles 21–30,
    /// difícil (4 cajas) con los niveles 41–50.
    public var requiredCampaignGroup: Int {
        switch self {
        case .easy: 0
        case .medium: 2
        case .hard: 4
        }
    }
}

/// Parámetros del generador.
public struct GeneratorSettings: Hashable, Codable, Sendable {
    /// Ancho y alto de la habitación en bloques de 3×3 (antes de recortar).
    public var blocksWide: Int
    public var blocksHigh: Int
    /// Número de cajas.
    public var boxes: Int
    /// Mínimo de empujes de la solución óptima para aceptar el nivel.
    public var minPushes: Int
    /// Máximo de empujes (para no pasarse en los primeros niveles). `nil` = sin máximo.
    public var maxPushes: Int?
    /// Colocaciones de destinos que se prueban por habitación (se queda la mejor).
    public var attempts: Int
    /// Habitaciones que se prueban antes de rendirse.
    public var maxRooms: Int
    /// Límite de posiciones de la búsqueda hacia atrás por intento.
    public var maxSearchStates: Int

    public init(blocksWide: Int, blocksHigh: Int, boxes: Int, minPushes: Int, maxPushes: Int? = nil,
                attempts: Int = 4, maxRooms: Int = 300, maxSearchStates: Int = 60_000) {
        self.blocksWide = blocksWide
        self.blocksHigh = blocksHigh
        self.boxes = boxes
        self.minPushes = minPushes
        self.maxPushes = maxPushes
        self.attempts = attempts
        self.maxRooms = maxRooms
        self.maxSearchStates = maxSearchStates
    }

    /// Ajustes del modo libre según la dificultad.
    public static func preset(_ difficulty: Difficulty) -> GeneratorSettings {
        switch difficulty {
        case .easy: GeneratorSettings(blocksWide: 2, blocksHigh: 2, boxes: 2, minPushes: 6, maxPushes: 14)
        case .medium: GeneratorSettings(blocksWide: 3, blocksHigh: 2, boxes: 3, minPushes: 14, maxPushes: 30)
        case .hard: GeneratorSettings(blocksWide: 3, blocksHigh: 3, boxes: 4, minPushes: 24)
        }
    }
}

/// Un nivel generado, con su solución óptima y su puntuación de dificultad.
public struct GeneratedLevel: Sendable {
    public let level: Level
    public let seed: UInt64
    public let solution: Solution
    /// Veces que el jugador tiene que cambiar de caja en la solución (más = más difícil).
    public let boxChanges: Int

    /// Puntuación de dificultad: empujes óptimos más una penalización por cambiar de caja.
    public var score: Int { solution.pushCount + 2 * boxChanges }
}

/// Errores del generador.
public enum GeneratorError: Error, Sendable {
    /// No se encontró un nivel válido con esos parámetros.
    case noLevelFound
    case cancelled
}

/// Generador procedural de niveles con solución garantizada.
///
/// 1. Construye una habitación combinando bloques de 3×3 (`RoomBuilder`).
/// 2. Elige destinos al azar y pone las cajas sobre ellos (el nivel resuelto).
/// 3. Búsqueda en anchura **hacia atrás**: el jugador *tira* de las cajas (un tirón es un empuje
///    al revés). La profundidad a la que aparece cada posición es exactamente el mínimo de empujes
///    para resolverla, así que el nivel siempre tiene solución y se conoce su dificultad real.
/// 4. Toma una de las posiciones más profundas dentro de `minPushes...maxPushes`, la resuelve con
///    `Solver` para obtener la secuencia de movimientos y la puntúa; se queda con el mejor intento.
///
/// El resultado depende solo de la semilla y los ajustes: la misma semilla da siempre el mismo nivel.
public enum LevelGenerator {
    public static func generate(seed: UInt64, settings: GeneratorSettings,
                                isCancelled: () -> Bool = { false }) throws(GeneratorError) -> GeneratedLevel {
        var rng = SeededRandom(seed: seed)
        let minFloor = settings.boxes * 3 + 6

        for _ in 0..<settings.maxRooms {
            if isCancelled() { throw .cancelled }
            guard let room = RoomBuilder.build(blocksWide: settings.blocksWide, blocksHigh: settings.blocksHigh,
                                               minFloor: minFloor, rng: &rng) else { continue }
            let board = makeBoard(room: room)
            var best: GeneratedLevel?
            for _ in 0..<settings.attempts {
                if isCancelled() { throw .cancelled }
                guard let level = deepestLevel(on: board, settings: settings, rng: &rng),
                      let solution = Solver(maxStates: 2_000_000).solve(level, isCancelled: isCancelled).solution
                else { continue }
                let candidate = GeneratedLevel(level: level, seed: seed, solution: solution,
                                               boxChanges: boxChanges(level, solution))
                if best == nil || candidate.score > best!.score { best = candidate }
            }
            if let best { return best }
        }
        throw .noLevelFound
    }

    /// Genera un nivel fuera del hilo principal. Se puede cancelar cancelando la tarea.
    @concurrent
    public static func generate(seed: UInt64, settings: GeneratorSettings) async throws(GeneratorError) -> GeneratedLevel {
        try generate(seed: seed, settings: settings, isCancelled: { Task.isCancelled })
    }

    // MARK: - Tablero

    /// Tablero con la habitación rodeada de un borde de muro (aún sin destinos).
    static func makeBoard(room: RoomBuilder.Room) -> Board {
        let width = room.width + 2
        let height = room.height + 2
        var tiles = [Tile](repeating: .wall, count: width * height)
        for y in 0..<room.height {
            for x in 0..<room.width where room.isFloor(x, y) {
                tiles[(y + 1) * width + x + 1] = .floor
            }
        }
        return Board(width: width, height: height, tiles: tiles)
    }

    // MARK: - Búsqueda hacia atrás

    /// Elige destinos al azar y devuelve una de las posiciones más alejadas (en empujes) del nivel resuelto.
    static func deepestLevel(on board: Board, settings: GeneratorSettings, rng: inout SeededRandom) -> Level? {
        var floor = board.positions.filter { board[$0] == .floor }
        guard floor.count > settings.boxes + 1 else { return nil }
        rng.shuffle(&floor)
        let goals = Array(floor.prefix(settings.boxes))

        var tiles = board.positions.map { board[$0] }
        for g in goals { tiles[g.y * board.width + g.x] = .goal }
        let goalBoard = Board(width: board.width, height: board.height, tiles: tiles)

        var search = ReverseSearch(board: goalBoard)
        guard let state = search.deepest(goals: goals, settings: settings, rng: &rng) else { return nil }
        return try? Level(board: goalBoard, player: state.player, boxes: Set(state.boxes))
    }

    /// Cuenta cuántas veces cambia la caja empujada a lo largo de la solución.
    static func boxChanges(_ level: Level, _ solution: Solution) -> Int {
        var boxes = level.boxes.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        var player = level.player
        var last: Int?
        var changes = 0
        for d in solution.moves {
            let target = player.moved(d)
            if let slot = boxes.firstIndex(of: target) {
                if let last, last != slot { changes += 1 }
                last = slot
                boxes[slot] = target.moved(d)
            }
            player = target
        }
        return changes
    }
}

/// Búsqueda en anchura sobre «tirones» a partir del nivel resuelto.
private struct ReverseSearch {
    struct Key: Hashable {
        var boxes: [Int32]
        var zone: Int32
    }

    let grid: Grid
    private var stamp: [Int]
    private var generation = 0
    private var boxMap: [Bool]
    private var queue: [Int] = []

    init(board: Board) {
        grid = Grid(board: board)
        stamp = [Int](repeating: 0, count: grid.walls.count)
        boxMap = [Bool](repeating: false, count: grid.walls.count)
    }

    mutating func deepest(goals: [Position], settings: GeneratorSettings,
                          rng: inout SeededRandom) -> (boxes: [Position], player: Position)? {
        let goalIndices = goals.map { Int32(grid.index($0)) }.sorted()
        var seen: Set<Key> = []
        var layer: [(boxes: [Int32], player: Int)] = []

        // Estados iniciales: cajas en los destinos y el jugador en cada zona libre posible.
        setBoxes(goalIndices)
        var covered = [Bool](repeating: false, count: grid.walls.count)
        for i in grid.walls.indices where !grid.walls[i] && !boxMap[i] && !covered[i] {
            let zone = reach(from: i)
            for j in grid.walls.indices where stamp[j] == generation { covered[j] = true }
            seen.insert(Key(boxes: goalIndices, zone: Int32(zone)))
            layer.append((goalIndices, i))
        }
        clearBoxes(goalIndices)

        var depth = 0
        var candidates: [(boxes: [Int32], player: Int)] = []
        let maxDepth = settings.maxPushes ?? Int.max
        let goalSet = Set(goalIndices)

        while !layer.isEmpty, depth < maxDepth, seen.count < settings.maxSearchStates {
            var next: [(boxes: [Int32], player: Int)] = []
            for state in layer {
                setBoxes(state.boxes)
                _ = reach(from: state.player)
                let reachable = generation
                for (slot, box32) in state.boxes.enumerated() {
                    let box = Int(box32)
                    for d in Direction.allCases {
                        let o = grid.offset(d)
                        let stand = box + o          // donde está el jugador para tirar
                        let back = box + 2 * o       // adonde retrocede el jugador
                        guard stamp[stand] == reachable, !grid.walls[back], !boxMap[back] else { continue }
                        var boxes = state.boxes
                        boxes[slot] = Int32(stand)
                        boxes.sort()
                        boxMap[box] = false
                        boxMap[stand] = true
                        let zone = reachZone(from: back)
                        boxMap[stand] = false
                        boxMap[box] = true
                        let key = Key(boxes: boxes, zone: Int32(zone))
                        guard !seen.contains(key) else { continue }
                        seen.insert(key)
                        next.append((boxes, back))
                    }
                }
                clearBoxes(state.boxes)
            }
            if next.isEmpty { break }
            depth += 1
            layer = next
            let valid = layer.filter { $0.boxes.allSatisfy { !goalSet.contains($0) } }
            if depth >= settings.minPushes, !valid.isEmpty { candidates = valid }
        }

        guard !candidates.isEmpty else { return nil }
        let pick = rng.element(of: candidates)
        return (pick.boxes.map { grid.position(Int($0)) }, grid.position(pick.player))
    }

    private mutating func setBoxes(_ boxes: [Int32]) {
        for b in boxes { boxMap[Int(b)] = true }
    }

    private mutating func clearBoxes(_ boxes: [Int32]) {
        for b in boxes { boxMap[Int(b)] = false }
    }

    /// Zona alcanzable sin pisar `stamp` de la consulta en curso.
    private mutating func reachZone(from start: Int) -> Int {
        let saved = stamp
        let savedGeneration = generation
        let zone = reach(from: start)
        stamp = saved
        generation = savedGeneration
        return zone
    }

    private mutating func reach(from start: Int) -> Int {
        generation += 1
        let gen = generation
        queue.removeAll(keepingCapacity: true)
        queue.append(start)
        stamp[start] = gen
        var minIndex = start
        var head = 0
        let w = grid.width
        while head < queue.count {
            let c = queue[head]
            head += 1
            for n in [c - w, c + w, c - 1, c + 1] where stamp[n] != gen && !grid.walls[n] && !boxMap[n] {
                stamp[n] = gen
                if n < minIndex { minIndex = n }
                queue.append(n)
            }
        }
        return minIndex
    }
}
