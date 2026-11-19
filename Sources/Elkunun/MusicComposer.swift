// © 2026 App-Zilla. Licencia MIT.

import ElkununCore
import Foundation

/// Compone y renderiza la música ambiental del juego: un bucle tranquilo de unos 46 segundos
/// con sonoridad andina (escala pentatónica de La menor), sin usar melodías tradicionales ni grabaciones.
///
/// Capas:
/// - Drone grave (La y Mi) que respira lentamente.
/// - Arpegios de cuerda pulsada tipo charango (Karplus–Strong) sobre Lam – Do – Sol – Lam.
/// - Frases de quena generadas por un paseo aleatorio con semilla fija (siempre la misma melodía).
/// - Bombo suave en el primer tiempo y a contratiempo.
///
/// La cola del final se suma al principio para que el bucle empalme sin cortes.
enum MusicComposer {
    static let bpm = 84.0
    static let bars = 16
    static let beatsPerBar = 4

    static var beat: Double { 60 / bpm }
    static var loopSeconds: Double { Double(bars * beatsPerBar) * beat }

    /// Pentatónica de La menor (A C D E G) en varias octavas, en Hz.
    private static let pentatonic: [Double] = [
        220.00, 261.63, 293.66, 329.63, 392.00,
        440.00, 523.25, 587.33, 659.25, 783.99,
        880.00,
    ]

    /// Acordes por compás (notas para el arpegio).
    private static let chords: [[Double]] = [
        [220.00, 329.63, 440.00, 523.25, 659.25],   // Lam
        [261.63, 329.63, 392.00, 523.25, 659.25],   // Do
        [196.00, 293.66, 392.00, 493.88, 587.33],   // Sol
        [220.00, 329.63, 440.00, 523.25, 659.25],   // Lam
    ]

    /// Renderiza el bucle en estéreo (izquierda, derecha).
    @concurrent
    static func render() async -> (left: [Float], right: [Float]) {
        let sr = SoundSynth.sampleRate
        let loop = Int(loopSeconds * sr)
        let tail = Int(3 * sr)
        var left = [Float](repeating: 0, count: loop + tail)
        var right = left
        var rng = SeededRandom(seed: 0xE1C0_0F3E_0A11)

        func add(_ samples: [Float], at time: Double, gain: Float, pan: Float) {
            let offset = Int(time * sr)
            left.mix(samples, at: offset, gain: gain * (1 - pan) )
            right.mix(samples, at: offset, gain: gain * (1 + pan))
        }

        // Drone.
        let drone = SoundSynth.buffer(seconds: loopSeconds) { t, _ in
            let breathe = 0.75 + 0.25 * sin(2 * .pi * t / (loopSeconds / 4))
            return breathe * (sin(2 * .pi * 110 * t) + 0.6 * sin(2 * .pi * 164.81 * t)
                + 0.3 * sin(2 * .pi * 110.4 * t) + 0.15 * sin(2 * .pi * 220 * t))
        }
        add(drone, at: 0, gain: 0.05, pan: 0)

        // Arpegios de charango: corcheas con algunos silencios.
        let eighth = beat / 2
        for bar in 0..<bars {
            let chord = chords[bar % chords.count]
            let pattern = [0, 2, 1, 3, 2, 4, 3, 1]
            for (k, index) in pattern.enumerated() {
                if k > 0, rng.chance(18) { continue }
                let time = Double(bar * beatsPerBar) * beat + Double(k) * eighth
                let note = chord[index] * 2  // registro agudo, como el charango
                let pluck = SoundSynth.pluck(note, seconds: 1.2, rng: &rng, damping: 0.994)
                add(pluck, at: time, gain: k == 0 ? 0.11 : 0.08, pan: -0.35)
            }
        }

        // Melodía de quena: dos frases de 4 compases (compases 5–8 y 13–16).
        for phraseStart in [4, 12] {
            var index = 5 + rng.int(below: 3)  // empieza alrededor de La4–Do5–Re5
            var time = Double(phraseStart * beatsPerBar) * beat
            let end = Double((phraseStart + 4) * beatsPerBar) * beat - beat
            while time < end {
                let lengths = [1.0, 1.0, 1.5, 2.0, 0.5]
                var length = rng.element(of: lengths) * beat
                if time + length > end { length = end - time }
                let note = SoundSynth.buffer(seconds: length + 0.3) { t, _ in
                    SoundSynth.flute(pentatonic[index], t, length: length)
                }
                add(note, at: time, gain: 0.07, pan: 0.3)
                time += length
                // Paso pequeño por la escala, a veces un silencio corto.
                index = min(pentatonic.count - 1, max(4, index + rng.element(of: [-2, -1, -1, 1, 1, 2])))
                if rng.chance(15) { time += beat / 2 }
            }
            // Cierra la frase en La.
            let close = SoundSynth.buffer(seconds: beat + 0.3) { t, _ in SoundSynth.flute(440, t, length: beat) }
            add(close, at: end, gain: 0.07, pan: 0.3)
        }

        // Bombo: golpe grave en el 1 y a contratiempo del 3.
        var phase = 0.0
        let kick = SoundSynth.buffer(seconds: 0.4) { t, dt in
            let f = 50 + 40 * exp(-t / 0.03)
            phase += 2 * .pi * f * dt
            return sin(phase) * SoundSynth.envelope(t, attack: 0.004, decay: 0.12)
        }
        for bar in 0..<bars {
            let start = Double(bar * beatsPerBar) * beat
            add(kick, at: start, gain: 0.16, pan: 0)
            add(kick, at: start + 2.5 * beat, gain: 0.09, pan: 0)
        }

        // Empalme: la cola vuelve al principio.
        for k in 0..<tail {
            left[k] += left[loop + k]
            right[k] += right[loop + k]
        }
        left.removeLast(tail)
        right.removeLast(tail)

        // Normalizar ambos canales juntos.
        let peak = max(left.map(abs).max() ?? 0, right.map(abs).max() ?? 0)
        if peak > 0.85 {
            let g = 0.85 / peak
            left = left.map { $0 * g }
            right = right.map { $0 * g }
        }
        return (left, right)
    }
}
