// © 2026 App-Zilla. Licencia MIT.

/// Tipo de casilla fija del tablero.
public enum Tile: Sendable {
    case wall
    case floor
    case goal
}

/// Parte fija del nivel: muros, suelo y destinos.
public struct Board: Hashable, Sendable {
    public let width: Int
    public let height: Int
    private let tiles: [Tile]

    public init(width: Int, height: Int, tiles: [Tile]) {
        precondition(width >= 0 && height >= 0 && tiles.count == width * height,
                     "El número de casillas no coincide con el tamaño del tablero")
        self.width = width
        self.height = height
        self.tiles = tiles
    }

    public func contains(_ p: Position) -> Bool {
        p.x >= 0 && p.y >= 0 && p.x < width && p.y < height
    }

    /// Casilla en la posición dada; fuera del tablero se considera muro.
    public subscript(_ p: Position) -> Tile {
        contains(p) ? tiles[p.y * width + p.x] : .wall
    }

    public func isWall(_ p: Position) -> Bool { self[p] == .wall }
    public func isGoal(_ p: Position) -> Bool { self[p] == .goal }

    /// Todas las posiciones de destino, de arriba abajo y de izquierda a derecha.
    public var goals: [Position] {
        positions.filter(isGoal)
    }

    /// Todas las posiciones del tablero, por filas.
    public var positions: [Position] {
        (0..<height).flatMap { y in (0..<width).map { x in Position(x: x, y: y) } }
    }
}

/// Errores al leer o validar un nivel.
public enum LevelError: Error, Equatable, Sendable {
    case empty
    case invalidCharacter(Character, line: Int, column: Int)
    case missingPlayer
    case multiplePlayers
    /// El jugador o una caja están sobre un muro, fuera del tablero, o comparten casilla.
    case overlapping
    case noBoxes
    case boxGoalMismatch(boxes: Int, goals: Int)
}

/// Un nivel completo: tablero fijo + posición del jugador y de las cajas.
public struct Level: Hashable, Sendable {
    public let board: Board
    public var player: Position
    public var boxes: Set<Position>

    public init(board: Board, player: Position, boxes: Set<Position>) throws(LevelError) {
        guard !board.isWall(player), !boxes.contains(player),
              boxes.allSatisfy({ !board.isWall($0) }) else { throw .overlapping }
        guard !boxes.isEmpty else { throw .noBoxes }
        let goalCount = board.goals.count
        guard boxes.count == goalCount else {
            throw .boxGoalMismatch(boxes: boxes.count, goals: goalCount)
        }
        self.board = board
        self.player = player
        self.boxes = boxes
    }

    /// `true` si todas las cajas están sobre un destino.
    public var isSolved: Bool {
        boxes.allSatisfy(board.isGoal)
    }
}

// MARK: - Formato XSB

extension Level {
    /// Lee un nivel en formato XSB, el estándar de texto del género:
    ///
    /// | Carácter | Significado |
    /// |---|---|
    /// | `#` | muro |
    /// | espacio, `-`, `_` | suelo |
    /// | `.` | destino |
    /// | `$` | caja |
    /// | `*` | caja sobre destino |
    /// | `@` | jugador |
    /// | `+` | jugador sobre destino |
    ///
    /// Las filas más cortas se completan con suelo. Las líneas vacías al inicio y al final se ignoran.
    public init(xsb text: String) throws(LevelError) {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.replacing("\r", with: "") }
        while let first = lines.first, first.allSatisfy(\.isWhitespace) { lines.removeFirst() }
        while let last = lines.last, last.allSatisfy(\.isWhitespace) { lines.removeLast() }
        guard !lines.isEmpty else { throw .empty }

        let width = lines.map(\.count).max() ?? 0
        let height = lines.count
        var tiles = [Tile](repeating: .floor, count: width * height)
        var player: Position?
        var boxes = Set<Position>()

        for (y, line) in lines.enumerated() {
            for (x, char) in line.enumerated() {
                let p = Position(x: x, y: y)
                let index = y * width + x
                switch char {
                case "#": tiles[index] = .wall
                case " ", "-", "_": break
                case ".": tiles[index] = .goal
                case "$": boxes.insert(p)
                case "*": tiles[index] = .goal; boxes.insert(p)
                case "@", "+":
                    guard player == nil else { throw .multiplePlayers }
                    player = p
                    if char == "+" { tiles[index] = .goal }
                default:
                    throw .invalidCharacter(char, line: y + 1, column: x + 1)
                }
            }
        }

        guard let player else { throw .missingPlayer }
        try self.init(board: Board(width: width, height: height, tiles: tiles), player: player, boxes: boxes)
    }

    /// Representación XSB del nivel (sin espacios sobrantes al final de cada fila).
    public var xsb: String {
        (0..<board.height).map { y in
            var row = ""
            for x in 0..<board.width {
                let p = Position(x: x, y: y)
                let goal = board.isGoal(p)
                if board.isWall(p) {
                    row.append("#")
                } else if p == player {
                    row.append(goal ? "+" : "@")
                } else if boxes.contains(p) {
                    row.append(goal ? "*" : "$")
                } else {
                    row.append(goal ? "." : " ")
                }
            }
            while row.last == " " { row.removeLast() }
            return row
        }.joined(separator: "\n")
    }
}
