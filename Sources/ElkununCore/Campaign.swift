// © 2026 App-Zilla. Licencia MIT.

/// Campaña de 60 niveles (6 grupos de 10) con dificultad creciente.
///
/// Los niveles se generaron con `LevelGenerator` a partir de semillas fijas y se guardaron en
/// `CampaignLevels.swift`, de modo que no cambian aunque el generador evolucione.
/// Para regenerarlos: `Scripts/generate-campaign.sh`.
public enum Campaign {
    public static let groupCount = 6
    public static let levelsPerGroup = 10
    public static let levelCount = groupCount * levelsPerGroup

    /// Un nivel de la campaña.
    public struct Entry: Sendable {
        /// Semilla con la que se generó (referencia).
        public let seed: UInt64
        /// Mínimo de empujes de la solución.
        public let optimalPushes: Int
        /// Mínimo de movimientos de esa solución (pasos + empujes).
        public let solutionMoves: Int
        /// Solución óptima en empujes, en notación LURD (para las pistas).
        public let solution: String
        /// Nivel en formato XSB.
        public let xsb: String

        public func level() -> Level {
            // Los niveles guardados se validaron al generarlos.
            try! Level(xsb: xsb)
        }
    }

    /// Todos los niveles en orden de juego.
    public static var entries: [Entry] { CampaignLevels.entries }

    /// Nivel de la campaña por índice (0..<60).
    public static func level(_ index: Int) -> Level {
        entries[index].level()
    }

    // MARK: - Parámetros de generación

    /// Semilla fija de cada nivel.
    public static func seed(for index: Int) -> UInt64 {
        SeededRandom.derive(0xE1C0_0F3E_2026_0001, UInt64(index))
    }

    /// Ajustes del generador para la semilla `index`: crece el tamaño, las cajas y los empujes.
    /// Después de generar, los 60 niveles se ordenan por puntuación, así que el nivel final
    /// número `n` no tiene por qué venir de la semilla `n`.
    public static func settings(for index: Int) -> GeneratorSettings {
        let group = index / levelsPerGroup
        let k = index % levelsPerGroup
        switch group {
        case 0 where k < 2:
            return GeneratorSettings(blocksWide: 2, blocksHigh: 2, boxes: 1, minPushes: 3 + k, maxPushes: 5 + k)
        case 0:
            return GeneratorSettings(blocksWide: 2, blocksHigh: 2, boxes: 2, minPushes: 4 + k / 2, maxPushes: 9 + k / 2)
        case 1:
            return GeneratorSettings(blocksWide: 3, blocksHigh: 2, boxes: 2, minPushes: 9 + k / 2, maxPushes: 16 + k / 2)
        case 2:
            return GeneratorSettings(blocksWide: 3, blocksHigh: 2, boxes: 3, minPushes: 13 + k / 2, maxPushes: 22 + k / 2)
        case 3:
            return GeneratorSettings(blocksWide: 3, blocksHigh: 3, boxes: 3, minPushes: 18 + k, maxPushes: 30 + k)
        case 4:
            return GeneratorSettings(blocksWide: 3, blocksHigh: 3, boxes: 4, minPushes: 24 + k, maxPushes: 40 + k)
        default:
            return GeneratorSettings(blocksWide: 4, blocksHigh: 3, boxes: 4, minPushes: 32 + k,
                                     maxSearchStates: 120_000)
        }
    }
}
