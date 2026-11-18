// © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Pantalla provisional hasta tener el tablero (Etapa 4) y el menú principal (Etapa 5).
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            StripeBand()
            Spacer()
            Text("Elkünufe")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.white)
            Text("El que guarda las cosas")
                .font(.title3)
                .foregroundStyle(Palette.white.opacity(0.8))
            Text("En desarrollo")
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Palette.red, in: Capsule())
                .foregroundStyle(Palette.white)
            Spacer()
            StripeBand()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.indigo)
    }
}

/// Franja geométrica simple, a modo de borde de telar.
private struct StripeBand: View {
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

#Preview {
    ContentView()
        .frame(width: 640, height: 480)
}
