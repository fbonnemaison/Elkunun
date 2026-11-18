// © 2026 App-Zilla. Licencia MIT.

/// Resultado de intentar un movimiento.
public enum MoveResult: Equatable, Sendable {
    /// El jugador avanzó a una casilla libre.
    case moved
    /// El jugador avanzó empujando una caja.
    case pushed
    /// No se pudo mover: muro, dos cajas seguidas, caja contra muro o nivel ya resuelto.
    case blocked
}

/// Un movimiento realizado, guardado en el historial para poder deshacerlo.
public struct Move: Hashable, Sendable {
    public let direction: Direction
    public let pushedBox: Bool
}

/// Partida en curso: aplica las reglas del juego sobre un nivel.
///
/// Reglas:
/// - El jugador se mueve en cuatro direcciones por casillas que no sean muro.
/// - Solo puede **empujar** cajas, nunca tirar de ellas.
/// - Solo puede empujar **una caja a la vez**: si detrás de la caja hay otra caja o un muro, no se mueve.
/// - Se gana cuando todas las cajas están sobre un destino.
public struct GameState: Sendable {
    /// Nivel tal como empezó (para reiniciar).
    public let initial: Level
    /// Estado actual del nivel.
    public private(set) var level: Level
    /// Movimientos realizados, del primero al último.
    public private(set) var history: [Move] = []
    /// Movimientos deshechos que aún se pueden rehacer.
    public private(set) var redoStack: [Move] = []
    /// Número de empujes en el estado actual.
    public private(set) var pushCount = 0

    public init(level: Level) {
        self.initial = level
        self.level = level
    }

    public var board: Board { level.board }
    public var player: Position { level.player }
    public var boxes: Set<Position> { level.boxes }
    public var isSolved: Bool { level.isSolved }

    /// Número de movimientos (pasos + empujes) en el estado actual.
    public var moveCount: Int { history.count }

    /// Historial en notación LURD (minúsculas = pasos, mayúsculas = empujes).
    public var lurd: String {
        String(history.map { $0.direction.lurd(pushed: $0.pushedBox) })
    }

    /// Indica qué pasaría al moverse en `direction`, sin cambiar el estado.
    public func outcome(of direction: Direction) -> MoveResult {
        guard !isSolved else { return .blocked }
        let target = player.moved(direction)
        if board.isWall(target) { return .blocked }
        if boxes.contains(target) {
            let beyond = target.moved(direction)
            if board.isWall(beyond) || boxes.contains(beyond) { return .blocked }
            return .pushed
        }
        return .moved
    }

    /// Intenta mover al jugador. Si el movimiento es válido, borra lo que hubiera para rehacer.
    @discardableResult
    public mutating func move(_ direction: Direction) -> MoveResult {
        let result = apply(direction)
        if result != .blocked { redoStack.removeAll() }
        return result
    }

    /// Deshace el último movimiento. Devuelve `false` si no hay nada que deshacer.
    @discardableResult
    public mutating func undo() -> Bool {
        guard let last = history.popLast() else { return false }
        let previous = player.moved(last.direction.opposite)
        if last.pushedBox {
            let boxNow = player.moved(last.direction)
            level.boxes.remove(boxNow)
            level.boxes.insert(player)
            pushCount -= 1
        }
        level.player = previous
        redoStack.append(last)
        return true
    }

    /// Rehace el último movimiento deshecho. Devuelve `false` si no hay nada que rehacer.
    @discardableResult
    public mutating func redo() -> Bool {
        guard let next = redoStack.popLast() else { return false }
        let result = apply(next.direction)
        assert(result != .blocked, "Un movimiento rehecho no debería estar bloqueado")
        return result != .blocked
    }

    /// Vuelve al estado inicial del nivel y borra el historial.
    public mutating func restart() {
        level = initial
        history.removeAll()
        redoStack.removeAll()
        pushCount = 0
    }

    private mutating func apply(_ direction: Direction) -> MoveResult {
        let result = outcome(of: direction)
        switch result {
        case .blocked:
            return .blocked
        case .pushed:
            let target = player.moved(direction)
            level.boxes.remove(target)
            level.boxes.insert(target.moved(direction))
            pushCount += 1
            level.player = target
        case .moved:
            level.player = player.moved(direction)
        }
        history.append(Move(direction: direction, pushedBox: result == .pushed))
        return result
    }
}
