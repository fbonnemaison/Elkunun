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
    static let warnStuck = "warnStuck"
    static let musicEnabled = "musicEnabled"
    static let campaignProgress = "campaignProgress"
    static let savedSession = "savedSession"
}

/// Lectura de ajustes desde código que no es SwiftUI (la escena, el audio).
enum Preferences {
    /// Registra los valores por defecto (deben coincidir con los de `@AppStorage`).
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            PreferenceKey.soundEnabled: true,
            PreferenceKey.effectsVolume: 0.8,
            PreferenceKey.musicVolume: 0.5,
            PreferenceKey.warnStuck: true,
            PreferenceKey.musicEnabled: true,
            // No restaurar «sin ventanas» al volver a abrir: siempre se abre la ventana principal.
            "NSQuitAlwaysKeepsWindows": false,
        ])
    }

    static var reduceMotion: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.reduceMotion)
            || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    static var fastAnimations: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.fastAnimations)
    }

    /// Marcar con «!» las cajas que quedan en un fondo de saco.
    static var warnStuck: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.warnStuck)
    }

    static var soundEnabled: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.soundEnabled)
    }

    /// Música activada (independiente de los efectos).
    static var musicEnabled: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.musicEnabled)
    }

    static var effectsVolume: Double {
        UserDefaults.standard.double(forKey: PreferenceKey.effectsVolume)
    }

    static var musicVolume: Double {
        UserDefaults.standard.double(forKey: PreferenceKey.musicVolume)
    }
}
