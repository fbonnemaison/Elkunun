// © 2026 App-Zilla. Licencia MIT.

/// Generador pseudoaleatorio con semilla (SplitMix64).
///
/// Se implementa a mano, junto con `int(below:)` y `shuffle`, para que una misma semilla produzca
/// **siempre** el mismo nivel, en cualquier versión de Swift o de macOS. Los métodos estándar
/// (`Int.random(in:using:)`, `shuffled(using:)`) no garantizan esa estabilidad.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Entero uniforme en `0..<bound` (sin sesgo).
    public mutating func int(below bound: Int) -> Int {
        precondition(bound > 0)
        let b = UInt64(bound)
        let limit = UInt64.max - UInt64.max % b
        while true {
            let r = next()
            if r < limit { return Int(r % b) }
        }
    }

    /// `true` con probabilidad `percent`/100.
    public mutating func chance(_ percent: Int) -> Bool {
        int(below: 100) < percent
    }

    public mutating func element<T>(of array: [T]) -> T {
        array[int(below: array.count)]
    }

    /// Mezcla de Fisher–Yates.
    public mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, to: 0, by: -1) {
            array.swapAt(i, int(below: i + 1))
        }
    }

    /// Deriva una semilla nueva y estable a partir de otra y un índice.
    public static func derive(_ seed: UInt64, _ index: UInt64) -> UInt64 {
        var r = SeededRandom(seed: seed ^ (index &* 0xD1B5_4A32_D192_ED03))
        return r.next()
    }
}
