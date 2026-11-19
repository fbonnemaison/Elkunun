// © 2026 App-Zilla. Licencia MIT.

/// Posición de una casilla en la cuadrícula. `x` crece hacia la derecha, `y` hacia abajo.
public struct Position: Hashable, Sendable, CustomStringConvertible {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    /// Casilla vecina en la dirección indicada.
    public func moved(_ direction: Direction) -> Position {
        Position(x: x + direction.dx, y: y + direction.dy)
    }

    public var description: String { "(\(x), \(y))" }
}

/// Las cuatro direcciones de movimiento.
public enum Direction: CaseIterable, Sendable {
    case up, down, left, right

    public var dx: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .up, .down: 0
        }
    }

    public var dy: Int {
        switch self {
        case .up: -1
        case .down: 1
        case .left, .right: 0
        }
    }

    public var opposite: Direction {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }

    /// Letra en notación LURD (minúscula = paso, mayúscula = empuje).
    public func lurd(pushed: Bool) -> Character {
        let letter: Character = switch self {
        case .left: "l"
        case .up: "u"
        case .right: "r"
        case .down: "d"
        }
        return pushed ? Character(letter.uppercased()) : letter
    }
}
