// © 2026 App-Zilla. Licencia MIT.

/// Solución de un nivel.
public struct Solution: Equatable, Sendable {
    /// Secuencia completa de movimientos (pasos y empujes).
    public let moves: [Direction]
    /// Número de empujes; es el mínimo posible para el nivel.
    public let pushCount: Int

    public var moveCount: Int { moves.count }

    /// Solución en notación LURD (minúsculas = pasos, mayúsculas = empujes).
    public let lurd: String
}

/// Resultado de intentar resolver un nivel.
public enum SolverResult: Equatable, Sendable {
    /// Se encontró una solución óptima en empujes.
    case solved(Solution)
    /// Se exploraron todas las posiciones alcanzables: el nivel no tiene solución.
    case unsolvable
    /// Se alcanzó el límite de posiciones o se canceló antes de terminar.
    case limitReached

    public var solution: Solution? {
        if case .solved(let s) = self { s } else { nil }
    }
}

/// Solucionador por búsqueda A* sobre empujes.
///
/// - Solo cuenta los empujes como pasos de la búsqueda; los pasos sueltos del jugador se resumen
///   en «a qué casillas puede llegar sin empujar nada».
/// - Heurística: suma, para cada caja, del mínimo de empujes hasta algún destino ignorando las
///   demás cajas. Es admisible y consistente, así que la solución es **óptima en empujes**.
/// - Poda: casillas muertas (desde donde una caja ya no puede llegar a ningún destino) y bloqueos
///   2×2 (cuatro casillas entre muros y cajas con alguna caja fuera de destino).
public struct Solver: Sendable {
    /// Máximo de posiciones distintas a explorar antes de rendirse.
    public var maxStates: Int

    public init(maxStates: Int = 1_000_000) {
        self.maxStates = maxStates
    }

    /// Resuelve el nivel. `isCancelled` se consulta periódicamente para poder abortar.
    public func solve(_ level: Level, isCancelled: () -> Bool = { false }) -> SolverResult {
        var search = Search(level: level)
        return search.run(maxStates: maxStates, isCancelled: isCancelled)
    }

    /// Casillas de suelo desde las que una caja ya no puede llegar a ningún destino,
    /// aunque no haya más cajas en el tablero. Una caja ahí deja el nivel sin solución.
    public static func deadSquares(of board: Board) -> Set<Position> {
        let grid = Grid(board: board)
        var result = Set<Position>()
        for p in board.positions where !board.isWall(p) && grid.distance[grid.index(p)] == Grid.unreachable {
            result.insert(p)
        }
        return result
    }
}

// MARK: - Tablero indexado

/// Tablero rodeado por un borde de muro e indexado con enteros, para buscar rápido.
struct Grid {
    static let unreachable = Int.max

    let width: Int
    let height: Int
    let walls: [Bool]
    let goals: [Bool]
    /// Mínimo de empujes desde cada casilla hasta algún destino (ignorando otras cajas).
    let distance: [Int]

    init(board: Board) {
        width = board.width + 2
        height = board.height + 2
        var walls = [Bool](repeating: true, count: width * height)
        var goals = [Bool](repeating: false, count: width * height)
        for p in board.positions {
            let i = (p.y + 1) * width + (p.x + 1)
            walls[i] = board.isWall(p)
            goals[i] = board.isGoal(p)
        }
        self.walls = walls
        self.goals = goals
        distance = Grid.pullDistances(width: width, walls: walls, goals: goals)
    }

    func index(_ p: Position) -> Int { (p.y + 1) * width + (p.x + 1) }

    func position(_ i: Int) -> Position { Position(x: i % width - 1, y: i / width - 1) }

    func offset(_ d: Direction) -> Int {
        switch d {
        case .up: -width
        case .down: width
        case .left: -1
        case .right: 1
        }
    }

    /// BFS «tirando» de las cajas desde todos los destinos: una caja en `b` puede haber llegado
    /// desde `b + d` si el jugador cabía en `b + 2d` para empujarla.
    private static func pullDistances(width: Int, walls: [Bool], goals: [Bool]) -> [Int] {
        var distance = [Int](repeating: unreachable, count: walls.count)
        var queue: [Int] = []
        for i in goals.indices where goals[i] {
            distance[i] = 0
            queue.append(i)
        }
        let offsets = [-width, width, -1, 1]
        var head = 0
        while head < queue.count {
            let b = queue[head]
            head += 1
            for o in offsets {
                let from = b + o
                let playerSpot = b + 2 * o
                guard playerSpot >= 0, playerSpot < walls.count,
                      !walls[from], !walls[playerSpot],
                      distance[from] == unreachable else { continue }
                distance[from] = distance[b] + 1
                queue.append(from)
            }
        }
        return distance
    }
}

// MARK: - Búsqueda

private struct StateKey: Hashable {
    /// Índices de las cajas, ordenados.
    var boxes: [Int32]
    /// Casilla alcanzable de menor índice: identifica la zona del jugador.
    var zone: Int32
}

private struct Node {
    let parent: Int
    let boxes: [Int32]
    let player: Int
    let zone: Int
    let pushFrom: Int
    let direction: Direction
    let g: Int
}

private struct Frontier {
    let node: Int
    let f: Int
    let h: Int
}

private struct Search {
    let level: Level
    let grid: Grid
    /// Marcas de casillas alcanzables (una «generación» por consulta, para no limpiar el arreglo).
    private var stamp: [Int]
    private var zoneStamp: [Int]
    private var generation = 0
    private var queue: [Int] = []
    private var boxMap: [Bool]

    init(level: Level) {
        self.level = level
        grid = Grid(board: level.board)
        stamp = [Int](repeating: 0, count: grid.walls.count)
        zoneStamp = [Int](repeating: 0, count: grid.walls.count)
        boxMap = [Bool](repeating: false, count: grid.walls.count)
    }

    mutating func run(maxStates: Int, isCancelled: () -> Bool) -> SolverResult {
        let startBoxes = level.boxes.map { Int32(grid.index($0)) }.sorted()
        let startPlayer = grid.index(level.player)

        // Cualquier caja inicial en casilla muerta: sin solución.
        if startBoxes.contains(where: { grid.distance[Int($0)] == Grid.unreachable }) {
            return .unsolvable
        }

        setBoxes(startBoxes)
        let startZone = reach(from: startPlayer)
        clearBoxes(startBoxes)
        var nodes: [Node] = [Node(parent: -1, boxes: startBoxes, player: startPlayer, zone: startZone,
                                  pushFrom: -1, direction: .up, g: 0)]
        var bestG: [StateKey: Int] = [:]
        var open = PriorityQueue<Frontier> { a, b in
            a.f != b.f ? a.f < b.f : a.h < b.h
        }

        let startH = heuristic(startBoxes)
        bestG[StateKey(boxes: startBoxes, zone: Int32(startZone))] = 0
        open.push(Frontier(node: 0, f: startH, h: startH))

        var expanded = 0
        while let current = open.pop() {
            let node = nodes[current.node]
            if current.h == 0 {
                return .solved(reconstruct(nodes: nodes, goal: current.node))
            }
            let key = StateKey(boxes: node.boxes, zone: Int32(node.zone))
            if let g = bestG[key], g < node.g { continue }

            expanded += 1
            if expanded > maxStates { return .limitReached }
            if expanded & 1023 == 1, isCancelled() { return .limitReached }

            setBoxes(node.boxes)
            _ = reach(from: node.player)
            let reachable = generation

            for (slot, box32) in node.boxes.enumerated() {
                let box = Int(box32)
                for direction in Direction.allCases {
                    let o = grid.offset(direction)
                    let playerSpot = box - o
                    let target = box + o
                    guard stamp[playerSpot] == reachable,
                          !grid.walls[target], !boxMap[target],
                          grid.distance[target] != Grid.unreachable,
                          !isFrozen2x2(after: box, to: target) else { continue }

                    var newBoxes = node.boxes
                    newBoxes[slot] = Int32(target)
                    newBoxes.sort()
                    let g = node.g + 1

                    // Zona del jugador tras el empuje (el jugador queda donde estaba la caja).
                    boxMap[box] = false
                    boxMap[target] = true
                    let zone = reach(from: box, useZoneBuffer: true)
                    boxMap[target] = false
                    boxMap[box] = true

                    let newKey = StateKey(boxes: newBoxes, zone: Int32(zone))
                    if let old = bestG[newKey], old <= g { continue }
                    bestG[newKey] = g
                    let h = heuristic(newBoxes)
                    nodes.append(Node(parent: current.node, boxes: newBoxes, player: box, zone: zone,
                                      pushFrom: box, direction: direction, g: g))
                    open.push(Frontier(node: nodes.count - 1, f: g + h, h: h))
                }
            }
            clearBoxes(node.boxes)
        }
        return .unsolvable
    }

    // MARK: Utilidades

    private func heuristic(_ boxes: [Int32]) -> Int {
        boxes.reduce(0) { $0 + grid.distance[Int($1)] }
    }

    private mutating func setBoxes(_ boxes: [Int32]) {
        for b in boxes { boxMap[Int(b)] = true }
    }

    private mutating func clearBoxes(_ boxes: [Int32]) {
        for b in boxes { boxMap[Int(b)] = false }
    }

    /// Marca con la generación actual las casillas alcanzables desde `start` sin empujar cajas.
    /// Devuelve el menor índice alcanzado (identificador canónico de la zona).
    /// Con `useZoneBuffer` usa un segundo arreglo de marcas para no pisar el de la consulta en curso.
    private mutating func reach(from start: Int, useZoneBuffer: Bool = false) -> Int {
        if useZoneBuffer { swap(&stamp, &zoneStamp) }
        defer { if useZoneBuffer { swap(&stamp, &zoneStamp) } }
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

    /// `true` si al mover la caja de `from` a `to` queda un bloque 2×2 de muros/cajas
    /// con alguna caja fuera de destino (ninguna de esas cajas podrá moverse jamás).
    private func isFrozen2x2(after from: Int, to: Int) -> Bool {
        let w = grid.width
        func blocked(_ i: Int) -> Bool { i != from && (grid.walls[i] || boxMap[i] || i == to) }
        func looseBox(_ i: Int) -> Bool { i != from && (boxMap[i] || i == to) && !grid.goals[i] }
        for corner in [to, to - 1, to - w, to - w - 1] {
            let square = [corner, corner + 1, corner + w, corner + w + 1]
            if square.allSatisfy(blocked), square.contains(where: looseBox) { return true }
        }
        return false
    }

    /// Reconstruye la secuencia completa de movimientos a partir de la cadena de empujes.
    private mutating func reconstruct(nodes: [Node], goal: Int) -> Solution {
        var pushes: [(from: Int, direction: Direction)] = []
        var i = goal
        while nodes[i].parent >= 0 {
            pushes.append((nodes[i].pushFrom, nodes[i].direction))
            i = nodes[i].parent
        }
        pushes.reverse()

        var boxes = nodes[0].boxes
        var player = nodes[0].player
        var moves: [Direction] = []
        var lurd = ""
        for push in pushes {
            setBoxes(boxes)
            let walk = path(from: player, to: push.from - grid.offset(push.direction))
            clearBoxes(boxes)
            for d in walk {
                moves.append(d)
                lurd.append(d.lurd(pushed: false))
            }
            moves.append(push.direction)
            lurd.append(push.direction.lurd(pushed: true))
            if let slot = boxes.firstIndex(of: Int32(push.from)) {
                boxes[slot] = Int32(push.from + grid.offset(push.direction))
            }
            player = push.from
        }
        return Solution(moves: moves, pushCount: pushes.count, lurd: lurd)
    }

    /// Camino más corto del jugador sin empujar cajas (las cajas deben estar en `boxMap`).
    private func path(from start: Int, to goal: Int) -> [Direction] {
        if start == goal { return [] }
        var cameFrom = [Int: (Int, Direction)]()
        var queue = [start]
        var head = 0
        var seen: Set<Int> = [start]
        while head < queue.count {
            let c = queue[head]
            head += 1
            for d in Direction.allCases {
                let n = c + grid.offset(d)
                guard !grid.walls[n], !boxMap[n], !seen.contains(n) else { continue }
                seen.insert(n)
                cameFrom[n] = (c, d)
                if n == goal {
                    var result: [Direction] = []
                    var k = n
                    while k != start, let (prev, dir) = cameFrom[k] {
                        result.append(dir)
                        k = prev
                    }
                    return result.reversed()
                }
                queue.append(n)
            }
        }
        preconditionFailure("La zona del jugador garantiza que existe camino")
    }
}
