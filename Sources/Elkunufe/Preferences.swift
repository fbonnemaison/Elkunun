// © 2026 App-Zilla. Licencia MIT.

import AppKit

/// Claves de ajustes guardados en `UserDefaults` (se usan con `@AppStorage` en SwiftUI).
enum PreferenceKey {
    static let highContrast = "highContrast"
    static let reduceMotion = "reduceMotion"
    static let fastAnimations = "fastAnimations"
    static let soundEnabled = "soundEnabled"
    static let effectsVolume = "effectsVolume"
    static let musicVolume = "musicVolume"
    static let campaignProgress = "campaignProgress"
}

/// Lectura de ajustes desde código que no es SwiftUI (la escena, el audio).
enum Preferences {
    /// Registra los valores por defecto (deben coincidir con los de `@AppStorage`).
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            PreferenceKey.soundEnabled: true,
            PreferenceKey.effectsVolume: 0.8,
            PreferenceKey.musicVolume: 0.5,
        ])
    }

    static var reduceMotion: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.reduceMotion)
            || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    static var fastAnimations: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.fastAnimations)
    }

    static var soundEnabled: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.soundEnabled)
    }

    static var effectsVolume: Double {
        UserDefaults.standard.double(forKey: PreferenceKey.effectsVolume)
    }

    static var musicVolume: Double {
        UserDefaults.standard.double(forKey: PreferenceKey.musicVolume)
    }
}
