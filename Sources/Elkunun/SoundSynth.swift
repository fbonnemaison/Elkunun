// © 2026 App-Zilla. Licencia MIT.

import ElkununCore
import Foundation

/// Síntesis de los efectos de sonido. Todo se genera con código (sin grabaciones), así que el
/// audio del juego es original. Las muestras son `Float` mono a `sampleRate`.
enum SoundSynth {
    static let sampleRate: Double = 44_100

    enum Effect: CaseIterable, Sendable {
        case step, push, bump, goal, undo, victory, hint
    }

    /// Variantes de cada efecto (los pasos tienen varias para no sonar repetitivos).
    static func render(_ effect: Effect) -> [[Float]] {
        variants(effect).map { $0.fadedOut(seconds: 0.01) }
    }

    private static func variants(_ effect: Effect) -> [[Float]] {
        switch effect {
        case .step: (0..<4).map { step(variant: $0) }
        case .push: [push()]
        case .bump: [bump()]
        case .goal: [goal()]
        case .undo: [undo()]
        case .victory: [victory()]
        case .hint: [hint()]
        }
    }

    // MARK: - Efectos

    /// Pisada suave: ruido filtrado muy corto con un toque grave.
    private static func step(variant: Int) -> [Float] {
        var rng = SeededRandom(seed: 0x57E9 + UInt64(variant))
        let cutoff = 900 + Double(variant) * 180
        let pitch = 160 + Double(variant) * 14
        return [Float](repeating: 0, count: Int(0.08 * sampleRate))
            .withNoise(&rng, cutoff: cutoff, gain: 0.30) { t in envelope(t, attack: 0.002, decay: 0.022) }
            .adding(seconds: 0.08) { t in sin(2 * .pi * pitch * t) * envelope(t, attack: 0.002, decay: 0.02) * 0.18 }
    }

    /// Empuje: golpe grave de madera que baja de tono, con un leve roce.
    private static func push() -> [Float] {
        var rng = SeededRandom(seed: 0x9054)
        var phase = 0.0
        return buffer(seconds: 0.2) { t, dt in
            let f = 90 + 60 * exp(-t / 0.04)
            phase += 2 * .pi * f * dt
            return sin(phase) * envelope(t, attack: 0.003, decay: 0.07) * 0.6
        }
        .withNoise(&rng, cutoff: 600, gain: 0.16) { t in envelope(t, attack: 0.01, decay: 0.06) }
    }

    /// Choque contra un muro: golpe sordo y corto.
    private static func bump() -> [Float] {
        var phase = 0.0
        return buffer(seconds: 0.14) { t, dt in
            let f = 62 + 30 * exp(-t / 0.02)
            phase += 2 * .pi * f * dt
            return sin(phase) * envelope(t, attack: 0.002, decay: 0.04) * 0.5
        }
    }

    /// Caja guardada: dos campanitas en la escala pentatónica (La y Mi).
    private static func goal() -> [Float] {
        let notes: [(Double, Double)] = [(0, 880.0), (0.09, 1318.5)]
        return buffer(seconds: 1.0) { t, _ in
            notes.reduce(0) { sum, note in
                let local = t - note.0
                guard local >= 0 else { return sum }
                return sum + bell(note.1, local, decay: 0.35) * 0.22
            }
        }
    }

    /// Deshacer: blip suave que baja.
    private static func undo() -> [Float] {
        var phase = 0.0
        return buffer(seconds: 0.11) { t, dt in
            let f = 540 - 1500 * t
            phase += 2 * .pi * f * dt
            return sin(phase) * envelope(t, attack: 0.004, decay: 0.04) * 0.18
        }
    }

    /// Pista: dos notas de marimba (Mi → La).
    private static func hint() -> [Float] {
        buffer(seconds: 0.5) { t, _ in
            marimba(659.25, t, decay: 0.12) * 0.22 + marimba(880, t - 0.1, decay: 0.15) * 0.22
        }
    }

    /// Victoria: arpegio ascendente de flauta andina (pentatónica de La menor) y un rasgueo final.
    private static func victory() -> [Float] {
        let notes = [440.0, 523.25, 587.33, 659.25, 783.99, 880.0]
        let gap = 0.12
        var out = buffer(seconds: 2.6) { t, _ in
            var sum = 0.0
            for (i, f) in notes.enumerated() {
                let start = Double(i) * gap
                let length = i == notes.count - 1 ? 1.1 : gap * 1.6
                sum += flute(f, t - start, length: length) * 0.2
            }
            return sum
        }
        // Rasgueo de cuerdas (Karplus–Strong) con el acorde de La menor.
        var rng = SeededRandom(seed: 0xC4A2)
        for (i, f) in [220.0, 329.63, 440.0, 523.25, 659.25].enumerated() {
            let pluck = Self.pluck(f, seconds: 1.6, rng: &rng)
            out.mix(pluck, at: Int((0.72 + Double(i) * 0.025) * sampleRate), gain: 0.16)
        }
        return out.normalized(peak: 0.8)
    }

    // MARK: - Instrumentos

    /// Campana: fundamental más parciales inarmónicos que se apagan antes.
    static func bell(_ f: Double, _ t: Double, decay: Double) -> Double {
        guard t >= 0 else { return 0 }
        let a = envelope(t, attack: 0.002, decay: decay)
        return a * (sin(2 * .pi * f * t)
            + 0.35 * sin(2 * .pi * f * 2.76 * t) * exp(-t / (decay * 0.4))
            + 0.15 * sin(2 * .pi * f * 5.4 * t) * exp(-t / (decay * 0.2)))
    }

    static func marimba(_ f: Double, _ t: Double, decay: Double) -> Double {
        guard t >= 0 else { return 0 }
        let a = envelope(t, attack: 0.002, decay: decay)
        return a * (sin(2 * .pi * f * t) + 0.25 * sin(2 * .pi * f * 4 * t) * exp(-t / 0.02))
    }

    /// Flauta tipo quena: casi senoidal, con armónicos suaves, vibrato tardío y algo de soplo.
    static func flute(_ f: Double, _ t: Double, length: Double) -> Double {
        guard t >= 0, t < length + 0.25 else { return 0 }
        let attack = min(1, t / 0.04)
        let release = t > length ? max(0, 1 - (t - length) / 0.25) : 1
        let vibrato = t > 0.15 ? 1 + 0.004 * sin(2 * .pi * 5.5 * t) : 1
        let p = 2 * .pi * f * vibrato * t
        let breath = sin(t * 9_731.0) * sin(t * 13_217.0) * 0.04 * exp(-t / 0.08)
        return attack * release * (sin(p) + 0.22 * sin(2 * p) + 0.07 * sin(3 * p) + breath)
    }

    /// Cuerda pulsada (algoritmo de Karplus–Strong), con timbre parecido a un charango.
    static func pluck(_ f: Double, seconds: Double, rng: inout SeededRandom, damping: Double = 0.996) -> [Float] {
        let n = max(2, Int(sampleRate / f))
        var ring = (0..<n).map { _ in Double(rng.int(below: 2001) - 1000) / 1000 }
        let count = Int(seconds * sampleRate)
        var out = [Float](repeating: 0, count: count)
        var i = 0
        for k in 0..<count {
            let next = (i + 1) % n
            let value = 0.5 * (ring[i] + ring[next]) * damping
            out[k] = Float(ring[i])
            ring[i] = value
            i = next
        }
        // Ataque un poco más suave.
        for k in 0..<min(count, 60) { out[k] *= Float(k) / 60 }
        return out
    }

    // MARK: - Utilidades

    /// Envolvente de ataque lineal y caída exponencial.
    static func envelope(_ t: Double, attack: Double, decay: Double) -> Double {
        guard t >= 0 else { return 0 }
        return t < attack ? t / attack : exp(-(t - attack) / decay)
    }

    /// Crea un búfer evaluando `sample(t, dt)` para cada muestra.
    static func buffer(seconds: Double, _ sample: (Double, Double) -> Double) -> [Float] {
        let count = Int(seconds * sampleRate)
        let dt = 1 / sampleRate
        return (0..<count).map { Float(sample(Double($0) * dt, dt)) }
    }
}

extension Array where Element == Float {
    /// Suma ruido blanco filtrado (paso bajo de un polo) con la envolvente dada.
    func withNoise(_ rng: inout SeededRandom, cutoff: Double, gain: Double, envelope: (Double) -> Double) -> [Float] {
        let dt = 1 / SoundSynth.sampleRate
        let alpha = 1 - exp(-2 * .pi * cutoff * dt)
        var y = 0.0
        var out = self
        for k in indices {
            let white = Double(rng.int(below: 2001) - 1000) / 1000
            y += alpha * (white - y)
            out[k] += Float(y * gain * envelope(Double(k) * dt))
        }
        return out
    }

    /// Suma otra señal generada por `sample(t)`.
    func adding(seconds: Double, _ sample: (Double) -> Double) -> [Float] {
        let dt = 1 / SoundSynth.sampleRate
        var out = self
        let count = Int(seconds * SoundSynth.sampleRate)
        if out.count < count { out += [Float](repeating: 0, count: count - out.count) }
        for k in 0..<count { out[k] += Float(sample(Double(k) * dt)) }
        return out
    }

    /// Mezcla `other` a partir de la muestra `offset`.
    mutating func mix(_ other: [Float], at offset: Int, gain: Float) {
        guard offset < count else { return }
        for k in other.indices where offset + k < count {
            self[offset + k] += other[k] * gain
        }
    }

    /// Fundido lineal al final para que el corte no produzca un chasquido.
    func fadedOut(seconds: Double) -> [Float] {
        let n = Swift.min(count, Int(seconds * SoundSynth.sampleRate))
        guard n > 0 else { return self }
        var out = self
        for k in 0..<n {
            out[count - n + k] *= Float(n - k) / Float(n)
        }
        return out
    }

    /// Escala para que el pico sea `peak` (si se pasa de él).
    func normalized(peak: Float) -> [Float] {
        let maxValue = self.map(abs).max() ?? 0
        guard maxValue > peak else { return self }
        let g = peak / maxValue
        return map { $0 * g }
    }
}
