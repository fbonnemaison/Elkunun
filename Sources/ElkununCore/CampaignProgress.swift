// © 2026 App-Zilla. Licencia MIT.

/// Progreso del jugador en la campaña: niveles completados y mejores marcas.
///
/// Regla de desbloqueo por grupos de 10: al empezar están disponibles los niveles 1–10; al
/// completarlos todos se desbloquean los 11–20, y así sucesivamente. Dentro de un grupo
/// desbloqueado se pueden jugar los niveles en cualquier orden.
public struct CampaignProgress: Codable, Equatable, Sendable {
    /// Mejor marca de un nivel.
    public struct Record: Codable, Equatable, Sendable {
        public var bestMoves: Int
        public var bestPushes: Int
        /// Mejor tiempo en segundos (se guarda aparte: puede venir de otra partida).
        /// `nil` en progresos guardados antes de que existiera el reloj.
        public var bestSeconds: Int?

        public init(bestMoves: Int, bestPushes: Int, bestSeconds: Int? = nil) {
            self.bestMoves = bestMoves
            self.bestPushes = bestPushes
            self.bestSeconds = bestSeconds
        }
    }

    /// Marcas por índice de nivel (0…59).
    public private(set) var records: [Int: Record] = [:]

    public init() {}

    public var completedCount: Int { records.count }

    public func isCompleted(_ index: Int) -> Bool { records[index] != nil }

    public func isUnlocked(_ index: Int) -> Bool {
        guard (0..<Campaign.levelCount).contains(index) else { return false }
        return isGroupUnlocked(index / Campaign.levelsPerGroup) || isCompleted(index)
    }

    /// Un grupo está desbloqueado si es el primero o si el anterior está completo.
    public func isGroupUnlocked(_ group: Int) -> Bool {
        guard (0..<Campaign.groupCount).contains(group) else { return false }
        return group == 0 || isGroupCompleted(group - 1)
    }

    public func isGroupCompleted(_ group: Int) -> Bool {
        let start = group * Campaign.levelsPerGroup
        return (start..<start + Campaign.levelsPerGroup).allSatisfy(isCompleted)
    }

    /// Número de grupos desbloqueados (1…6).
    public var unlockedGroupCount: Int {
        (0..<Campaign.groupCount).filter(isGroupUnlocked).count
    }

    /// Las dificultades del modo aleatorio se desbloquean con la campaña: cada una exige el
    /// grupo de la campaña con su mismo número de cajas.
    public func isUnlocked(_ difficulty: Difficulty) -> Bool {
        isGroupUnlocked(difficulty.requiredCampaignGroup)
    }

    /// Primer nivel sin completar (o el último, si están todos).
    public var nextLevel: Int {
        (0..<Campaign.levelCount).first { !isCompleted($0) } ?? Campaign.levelCount - 1
    }

    /// Registra un nivel completado. Devuelve `true` si mejora la marca anterior
    /// (menos empujes, o igual empujes y menos movimientos). El mejor tiempo se guarda
    /// por separado y no cuenta para esa comparación.
    @discardableResult
    public mutating func complete(_ index: Int, moves: Int, pushes: Int, seconds: Int? = nil) -> Bool {
        guard let old = records[index] else {
            records[index] = Record(bestMoves: moves, bestPushes: pushes, bestSeconds: seconds)
            return true
        }
        let bestSeconds = [old.bestSeconds, seconds].compactMap { $0 }.min()
        guard (pushes, moves) < (old.bestPushes, old.bestMoves) else {
            records[index]?.bestSeconds = bestSeconds
            return false
        }
        records[index] = Record(bestMoves: min(moves, old.bestMoves), bestPushes: pushes, bestSeconds: bestSeconds)
        return true
    }

    /// Suma de los mejores tiempos de los niveles completados (los que tienen tiempo).
    public var totalBestSeconds: Int {
        records.values.compactMap(\.bestSeconds).reduce(0, +)
    }

    /// Niveles completados con el mínimo de empujes.
    public var optimalCount: Int {
        records.keys.count { isOptimal($0) }
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
