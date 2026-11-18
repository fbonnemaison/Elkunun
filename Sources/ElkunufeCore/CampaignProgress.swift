// © 2026 App-Zilla. Licencia MIT.

/// Progreso del jugador en la campaña: niveles completados y mejores marcas.
///
/// Regla de desbloqueo: se puede jugar cualquier nivel hasta `skipAllowance` posiciones más allá
/// del último completado, para no quedarse atascado en uno difícil.
public struct CampaignProgress: Codable, Equatable, Sendable {
    /// Mejor marca de un nivel.
    public struct Record: Codable, Equatable, Sendable {
        public var bestMoves: Int
        public var bestPushes: Int

        public init(bestMoves: Int, bestPushes: Int) {
            self.bestMoves = bestMoves
            self.bestPushes = bestPushes
        }
    }

    /// Niveles que se pueden saltar por delante del último completado.
    public static let skipAllowance = 3

    /// Marcas por índice de nivel (0…59).
    public private(set) var records: [Int: Record] = [:]

    public init() {}

    public var completedCount: Int { records.count }

    public func isCompleted(_ index: Int) -> Bool { records[index] != nil }

    public func isUnlocked(_ index: Int) -> Bool {
        guard (0..<Campaign.levelCount).contains(index) else { return false }
        let frontier = (records.keys.max() ?? -1) + 1
        return index < frontier + Self.skipAllowance || isCompleted(index)
    }

    /// Primer nivel sin completar (o el último, si están todos).
    public var nextLevel: Int {
        (0..<Campaign.levelCount).first { !isCompleted($0) } ?? Campaign.levelCount - 1
    }

    /// Registra un nivel completado. Devuelve `true` si mejora la marca anterior
    /// (menos empujes, o igual empujes y menos movimientos).
    @discardableResult
    public mutating func complete(_ index: Int, moves: Int, pushes: Int) -> Bool {
        guard let old = records[index] else {
            records[index] = Record(bestMoves: moves, bestPushes: pushes)
            return true
        }
        guard (pushes, moves) < (old.bestPushes, old.bestMoves) else { return false }
        records[index] = Record(bestMoves: min(moves, old.bestMoves), bestPushes: pushes)
        return true
    }

    /// `true` si la mejor marca del nivel iguala el mínimo de empujes.
    public func isOptimal(_ index: Int) -> Bool {
        guard let r = records[index] else { return false }
        return r.bestPushes <= Campaign.entries[index].optimalPushes
    }

    public mutating func reset() {
        records = [:]
    }
}
