// © 2026 App-Zilla. Licencia MIT.

/// Código corto para compartir un nivel del modo libre: dificultad + semilla.
///
/// Formato: `D-XXXXXXXX`, donde `D` es 1 (fácil), 2 (media) o 3 (difícil) y `XXXXXXXX`
/// es la semilla en hexadecimal (8 cifras). Ejemplo: `2-9F3A0C1D`.
/// Al leer se ignoran mayúsculas/minúsculas, espacios y el guion.
public struct LevelCode: Hashable, Sendable, CustomStringConvertible {
    public let difficulty: Difficulty
    public let seed: UInt32

    public init(difficulty: Difficulty, seed: UInt32) {
        self.difficulty = difficulty
        self.seed = seed
    }

    /// Código aleatorio nuevo.
    public static func random<G: RandomNumberGenerator>(_ difficulty: Difficulty, using rng: inout G) -> LevelCode {
        LevelCode(difficulty: difficulty, seed: UInt32.random(in: .min ... .max, using: &rng))
    }

    public static func random(_ difficulty: Difficulty) -> LevelCode {
        var rng = SystemRandomNumberGenerator()
        return random(difficulty, using: &rng)
    }

    public init?(_ text: String) {
        let cleaned = text.uppercased().filter { !$0.isWhitespace && $0 != "-" }
        guard cleaned.count == 9,
              let d = cleaned.first?.wholeNumberValue, let difficulty = Difficulty(rawValue: d),
              cleaned.dropFirst().allSatisfy(\.isHexDigit),
              let seed = UInt32(cleaned.dropFirst(), radix: 16) else { return nil }
        self.init(difficulty: difficulty, seed: seed)
    }

    public var description: String {
        let hex = String(seed, radix: 16, uppercase: true)
        return "\(difficulty.rawValue)-\(String(repeating: "0", count: 8 - hex.count))\(hex)"
    }

    /// Semilla completa del generador; incluye la dificultad para que cada una dé niveles distintos.
    public var generatorSeed: UInt64 {
        SeededRandom.derive(UInt64(seed), UInt64(difficulty.rawValue))
    }

    /// Genera el nivel de este código.
    public func generate(isCancelled: () -> Bool = { false }) throws(GeneratorError) -> GeneratedLevel {
        try LevelGenerator.generate(seed: generatorSeed, settings: .preset(difficulty), isCancelled: isCancelled)
    }

    /// Genera el nivel de este código fuera del hilo principal.
    @concurrent
    public func generate() async throws(GeneratorError) -> GeneratedLevel {
        try await LevelGenerator.generate(seed: generatorSeed, settings: .preset(difficulty))
    }
}
