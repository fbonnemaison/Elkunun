// © 2026 App-Zilla. Licencia MIT.

import SwiftUI

@main
struct ElkunufeApp: App {
    @State private var app = AppModel()

    init() {
        Preferences.registerDefaults()
    }

    var body: some Scene {
        Window("Elkünufe", id: "main") {
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
