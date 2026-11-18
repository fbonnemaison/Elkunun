// © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Ventana de Ajustes (⌘,).
struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @AppStorage(PreferenceKey.highContrast) private var highContrast = false
    @AppStorage(PreferenceKey.reduceMotion) private var reduceMotion = false
    @AppStorage(PreferenceKey.fastAnimations) private var fastAnimations = false
    @AppStorage(PreferenceKey.soundEnabled) private var soundEnabled = true
    @AppStorage(PreferenceKey.effectsVolume) private var effectsVolume = 0.8
    @AppStorage(PreferenceKey.musicVolume) private var musicVolume = 0.5
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section("Sonido") {
                Toggle("Sonido", isOn: $soundEnabled)
                LabeledContent("Efectos") {
                    Slider(value: $effectsVolume, in: 0...1) { editing in
                        if !editing { AudioEngine.shared.play(.goal) }
                    }
                }
                .disabled(!soundEnabled)
                LabeledContent("Música") {
                    Slider(value: $musicVolume, in: 0...1)
                }
                .disabled(!soundEnabled)
            }
            Section("Aspecto") {
                Toggle("Contraste alto", isOn: $highContrast)
                Text("También se activa con «Aumentar contraste» en Accesibilidad de macOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Animación") {
                Toggle("Reducir animaciones", isOn: $reduceMotion)
                Toggle("Zorro más rápido", isOn: $fastAnimations)
                    .disabled(reduceMotion)
            }
            Section("Progreso") {
                LabeledContent("Niveles completados", value: "\(app.progress.completedCount) / 60")
                Button("Borrar progreso…", role: .destructive) { confirmReset = true }
                    .disabled(app.progress.completedCount == 0)
            }
        }
        .formStyle(.grouped)
        .onChange(of: soundEnabled) { AudioEngine.shared.applyVolumes() }
        .onChange(of: effectsVolume) { AudioEngine.shared.applyVolumes() }
        .onChange(of: musicVolume) { AudioEngine.shared.applyVolumes() }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .confirmationDialog("¿Borrar todo el progreso de la campaña?", isPresented: $confirmReset) {
            Button("Borrar", role: .destructive) { app.resetProgress() }
        } message: {
            Text("Se perderán los niveles completados y las mejores marcas. No se puede deshacer.")
        }
    }
}
