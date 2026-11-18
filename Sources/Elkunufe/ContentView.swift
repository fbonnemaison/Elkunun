// © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Raíz de la ventana. Por ahora abre directamente la campaña; el menú principal llega en la Etapa 5.
struct ContentView: View {
    var body: some View {
        GameView()
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

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
