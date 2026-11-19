// © 2026 App-Zilla. Licencia MIT.

import AppKit
import SwiftUI

/// Elkünun es una app de una sola ventana: al cerrarla, termina.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct ElkununApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var app = AppModel()

    init() {
        Preferences.registerDefaults()
    }

    var body: some Scene {
        Window("Elkünun", id: "main") {
            ContentView()
                .environment(app)
                .frame(minWidth: 720, minHeight: 540)
                .task { AudioEngine.shared.start() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 720)
        .commands { GameCommands(app: app) }

        Settings {
            SettingsView()
                .environment(app)
        }
    }
}
