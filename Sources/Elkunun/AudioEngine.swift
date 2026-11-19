// © 2026 App-Zilla. Licencia MIT.

import AVFoundation
import Foundation

/// Reproduce efectos y música con `AVAudioEngine`.
///
/// - Efectos: un grupo de reproductores que se turnan, para que varios sonidos se solapen sin cortes.
/// - Música: un reproductor en bucle con el búfer que compone `MusicComposer` (se genera en segundo plano).
/// - Volumen de efectos y de música por separado, y silencio total, desde los Ajustes.
@MainActor
final class AudioEngine {
    static let shared = AudioEngine()

    typealias Sound = SoundSynth.Effect

    private let engine = AVAudioEngine()
    private let sfxMixer = AVAudioMixerNode()
    private let musicMixer = AVAudioMixerNode()
    private let musicPlayer = AVAudioPlayerNode()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var buffers: [Sound: [AVAudioPCMBuffer]] = [:]
    private var musicBuffer: AVAudioPCMBuffer?
    private var started = false

    private let mono = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 1)!
    private let stereo = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 2)!

    private init() {}

    /// Prepara el motor y empieza la música. Se puede llamar varias veces.
    func start() {
        guard !started else { return }
        started = true

        for effect in Sound.allCases {
            buffers[effect] = SoundSynth.render(effect).compactMap { makeBuffer(mono: $0) }
        }

        engine.attach(sfxMixer)
        engine.attach(musicMixer)
        engine.attach(musicPlayer)
        engine.connect(sfxMixer, to: engine.mainMixerNode, format: mono)
        engine.connect(musicMixer, to: engine.mainMixerNode, format: stereo)
        engine.connect(musicPlayer, to: musicMixer, format: stereo)
        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: sfxMixer, format: mono)
            players.append(player)
        }
        applyVolumes()

        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine,
                                               queue: .main) { _ in
            // Cambio de salida de audio (auriculares, etc.): volver a arrancar.
            MainActor.assumeIsolated { AudioEngine.shared.restart() }
        }
        startEngine()

        Task {
            let (left, right) = await MusicComposer.render()
            musicBuffer = makeBuffer(left: left, right: right)
            playMusic()
        }
    }

    func play(_ sound: Sound) {
        guard started, Preferences.soundEnabled, engine.isRunning,
              let variants = buffers[sound], let buffer = variants.randomElement() else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    /// Aplica los volúmenes y el silencio guardados en los Ajustes.
    func applyVolumes() {
        engine.mainMixerNode.outputVolume = Preferences.soundEnabled ? 1 : 0
        sfxMixer.outputVolume = Float(Preferences.effectsVolume)
        musicMixer.outputVolume = Preferences.musicEnabled ? Float(Preferences.musicVolume) : 0
    }

    // MARK: - Interno

    private func startEngine() {
        engine.prepare()
        do {
            try engine.start()
        } catch {
            // Sin salida de audio disponible: el juego sigue en silencio.
        }
    }

    private func restart() {
        guard started else { return }
        startEngine()
        playMusic()
    }

    private func playMusic() {
        guard let musicBuffer, engine.isRunning else { return }
        musicPlayer.stop()
        musicPlayer.scheduleBuffer(musicBuffer, at: nil, options: .loops)
        musicPlayer.play()
    }

    private func makeBuffer(mono samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
        return buffer
    }

    private func makeBuffer(left: [Float], right: [Float]) -> AVAudioPCMBuffer? {
        let count = min(left.count, right.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: stereo, frameCapacity: AVAudioFrameCount(count)),
              let channels = buffer.floatChannelData else { return nil }
        buffer.frameLength = AVAudioFrameCount(count)
        left.withUnsafeBufferPointer { channels[0].update(from: $0.baseAddress!, count: count) }
        right.withUnsafeBufferPointer { channels[1].update(from: $0.baseAddress!, count: count) }
        return buffer
    }
}
