// © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Raíz de la ventana: muestra la pantalla actual con el borde de telar arriba y abajo.
struct ContentView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PreferenceKey.highContrast) private var highContrast = false

    var body: some View {
        VStack(spacing: 0) {
            StripeBand()
            Group {
                switch app.screen {
                case .menu: MainMenuView()
                case .campaign: CampaignSelectView()
                case .random: RandomLevelView()
                case .credits: CreditsView()
                case .scores: BestScoresView()
                case .game(let game): GameView(game: game).id(ObjectIdentifier(game))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            StripeBand()
        }
        .background(Color(cgColor: Theme.current(colorScheme, highContrast: highContrast).background))
    }
}

/// Franja geométrica de borde, como el remate de un telar: triángulos rojos y blancos sobre negro.
struct StripeBand: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 24
            var x: CGFloat = 0
            var index = 0
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + step / 2, y: 0))
                path.addLine(to: CGPoint(x: x + step, y: size.height))
                path.closeSubpath()
                context.fill(path, with: .color(index.isMultiple(of: 2) ? Palette.red : Palette.white))
                x += step
                index += 1
            }
        }
        .frame(height: 12)
        .background(Palette.black)
        .accessibilityHidden(true)
    }
}

/// Imagen del zorro para los menús.
struct FoxImage: View {
    var view: FoxArt.View = .front
    var size: CGFloat = 120
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(decorative: FoxArt.image(view, theme: .current(colorScheme, highContrast: false)), scale: 1)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Botón grande de los menús.
struct MenuButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pixel(16))
            .frame(minWidth: 240)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(prominent ? Palette.red : Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(prominent ? Palette.white : Color.primary)
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Cabecera de las pantallas secundarias con botón para volver.
struct ScreenHeader: View {
    let title: LocalizedStringKey
    let back: () -> Void

    var body: some View {
        HStack {
            Button(action: back) {
                Label("Volver", systemImage: "chevron.left")
            }
            .keyboardShortcut(.cancelAction)
            Spacer()
            Text(title).font(.pixel(20))
            Spacer()
            Label("Volver", systemImage: "chevron.left").hidden()
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
