// © 2026 App-Zilla. Licencia MIT.

/// Ayudas para la interfaz: caminar hasta una casilla y pistas.
extension GameState {
    /// Camino más corto del jugador hasta `target` sin empujar ninguna caja.
    /// Devuelve `[]` si ya está ahí y `nil` si no se puede llegar.
    public func path(to target: Position) -> [Direction]? {
        if target == player { return [] }
        guard board.contains(target), !board.isWall(target), !boxes.contains(target) else { return nil }
        var cameFrom: [Position: (Position, Direction)] = [:]
        var queue = [player]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            for d in Direction.allCases {
                let next = current.moved(d)
                guard next != player, cameFrom[next] == nil,
                      !board.isWall(next), !boxes.contains(next) else { continue }
                cameFrom[next] = (current, d)
                if next == target {
                    var result: [Direction] = []
                    var p = next
                    while let (prev, dir) = cameFrom[p] {
                        result.append(dir)
                        p = prev
                    }
                    return result.reversed()
                }
                queue.append(next)
            }
        }
        return nil
    }

    /// Pista: resuelve desde la posición actual y devuelve el siguiente empuje.
    public func hint(solver: Solver = Solver(maxStates: 300_000), isCancelled: () -> Bool = { false }) -> Hint {
        if isSolved { return .solved }
        switch solver.solve(level, isCancelled: isCancelled) {
        case .unsolvable:
            return .stuck
        case .limitReached:
            return .unknown
        case .solved(let solution):
            var p = player
            var walk: [Direction] = []
            for d in solution.moves {
                let next = p.moved(d)
                if boxes.contains(next) {
                    return .push(box: next, direction: d, walk: walk, remainingPushes: solution.pushCount)
                }
                walk.append(d)
                p = next
            }
            return .solved
        }
    }
}

/// Resultado de pedir una pista.
public enum Hint: Equatable, Sendable {
    /// Empuja `box` en `direction`; antes hay que caminar `walk`. Quedan `remainingPushes` como mínimo.
    case push(box: Position, direction: Direction, walk: [Direction], remainingPushes: Int)
    /// El nivel ya no tiene solución desde aquí (hay que deshacer o reiniciar).
    case stuck
    /// No se encontró a tiempo.
    case unknown
    /// Ya está resuelto.
    case solved
}
