// © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Raíz de la ventana: muestra la pantalla actual con el borde de telar arriba y abajo.
struct ContentView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PreferenceKey.highContrast) private var highContrast = false

    var body: some View {
        VStack(spacing: 0) {
            // El borde de telar solo adorna la pantalla de inicio.
            if isMenu { StripeBand() }
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
            if isMenu { StripeBand() }
        }
        .background(Color(cgColor: Theme.current(colorScheme, highContrast: highContrast).background))
        .overlay { SweepOverlay(progress: app.sweepProgress, seed: app.sweepSeed) }
    }

    private var isMenu: Bool {
        if case .menu = app.screen { true } else { false }
    }
}

/// Barrido de transición: una cortina negra con el borde en escalones irregulares de píxeles
/// y un filo rojo, que cruza la ventana de izquierda a derecha.
struct SweepOverlay: View {
    var progress: Double
    var seed: UInt64

    var body: some View {
        ZStack {
            SweepShape(progress: progress, seed: seed, extend: SweepShape.block).fill(Palette.red)
            SweepShape(progress: progress, seed: seed, extend: 0).fill(Palette.black)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct SweepShape: Shape {
    /// 0…1 la cortina entra desde la izquierda; 1…2 sale por la derecha.
    var progress: Double
    var seed: UInt64
    /// Cuánto se adelanta el borde delantero y se retrasa el trasero (para el filo rojo).
    var extend: CGFloat

    /// Alto de cada franja y tamaño de los escalones, en puntos.
    static let block: CGFloat = 16
    /// Lo más que se desvía una franja del borde medio.
    static let jag: CGFloat = block * 6

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard progress > 0, progress < 2 else { return path }
        let b = Self.block
        let travel = rect.width + Self.jag + 2 * b
        let rows = Int((rect.height / b).rounded(.up))
        for row in 0..<rows {
            let lead = Self.noise(seed, row) * Self.jag
            let trail = Self.noise(seed &+ 0x9E37, row) * Self.jag
            var right = min(progress, 1) * travel - lead + extend
            var left = progress > 1 ? (progress - 1) * travel - trail - extend : -b
            // Escalones de un bloque, como píxeles grandes.
            right = (right / b).rounded(.down) * b
            left = (left / b).rounded(.down) * b
            guard right > left else { continue }
            path.addRect(CGRect(x: rect.minX + left, y: rect.minY + CGFloat(row) * b,
                                width: right - left, height: b))
        }
        return path
    }

    /// Valor pseudoaleatorio estable entre 0 y 1 para cada franja. Las franjas vecinas se
    /// parecen un poco, para que el borde forme dientes y no ruido.
    private static func noise(_ seed: UInt64, _ row: Int) -> CGFloat {
        func hash(_ n: Int) -> CGFloat {
            var x = seed &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(bitPattern: Int64(n)) &* 0xBF58_476D_1CE4_E5B9
            x ^= x >> 31
            x = x &* 0x94D0_49BB_1331_11EB
            x ^= x >> 29
            return CGFloat(x % 1000) / 1000
        }
        return (hash(row / 3) * 2 + hash(row)) / 3
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

/// Retrato del zorro del icono, para la pantalla de inicio. `size` debe ser múltiplo de 32.
struct FoxPortrait: View {
    var size: CGFloat = 128

    var body: some View {
        Image(decorative: FoxArt.portraitImage(), scale: 1)
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
