// © 2026 App-Zilla. Licencia MIT.

import CoreGraphics
import SpriteKit

/// El protagonista: un zorro culpeo (*Lycalopex culpaeus*) geométrico.
/// Pelaje rojizo, patas y punta de la cola oscuras, hocico y garganta claros.
/// Tres vistas: de lado (mirando a la derecha; a la izquierda se refleja), de frente y de espaldas.
enum FoxArt {
    enum View {
        case side, front, back
    }

    static func texture(_ view: View, theme: Theme, pixels: Int) -> SKTexture {
        let image = TileArt.render(pixels: pixels) { ctx in
            ctx.setLineJoin(.round)
            ctx.setLineCap(.round)
            switch view {
            case .side: drawSide(ctx, theme)
            case .front: drawFront(ctx, theme)
            case .back: drawBack(ctx, theme)
            }
        }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return texture
    }

    // MARK: - Utilidades

    private static func polygon(_ points: [(CGFloat, CGFloat)]) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: points.map { CGPoint(x: $0.0, y: $0.1) })
        p.closeSubpath()
        return p
    }

    private static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h), transform: nil)
    }

    private static func fill(_ ctx: CGContext, _ path: CGPath, _ color: CGColor, outline: CGColor? = nil) {
        ctx.setFillColor(color)
        ctx.addPath(path)
        ctx.fillPath()
        if let outline {
            ctx.setStrokeColor(outline)
            ctx.setLineWidth(0.025)
            ctx.addPath(path)
            ctx.strokePath()
        }
    }

    /// Rellena `path` y pinta de `tip` la parte dentro de `tipRect`.
    private static func tail(_ ctx: CGContext, _ path: CGPath, _ t: Theme, tipRect: CGRect) {
        fill(ctx, path, t.fox)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.setFillColor(t.foxDark)
        ctx.fill(tipRect)
        ctx.restoreGState()
        ctx.setStrokeColor(t.foxDark)
        ctx.setLineWidth(0.025)
        ctx.addPath(path)
        ctx.strokePath()
    }

    private static func shadow(_ ctx: CGContext, _ t: Theme) {
        fill(ctx, ellipse(0.5, 0.14, 0.62, 0.1), t.foxDark.copy(alpha: 0.18)!)
    }

    // MARK: - Vistas

    private static func drawSide(_ ctx: CGContext, _ t: Theme) {
        shadow(ctx, t)

        // Cola tupida hacia atrás, con la punta negra.
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 0.31, y: 0.50))
        tailPath.addQuadCurve(to: CGPoint(x: 0.03, y: 0.44), control: CGPoint(x: 0.14, y: 0.66))
        tailPath.addQuadCurve(to: CGPoint(x: 0.31, y: 0.36), control: CGPoint(x: 0.12, y: 0.26))
        tailPath.closeSubpath()
        tail(ctx, tailPath, t, tipRect: CGRect(x: 0, y: 0, width: 0.1, height: 1))

        // Patas.
        ctx.setFillColor(t.foxDark)
        for x in [0.32, 0.40, 0.56, 0.64] {
            ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: 0.15, width: 0.055, height: 0.18),
                               cornerWidth: 0.02, cornerHeight: 0.02, transform: nil))
        }
        ctx.fillPath()

        // Cuerpo y pecho claro.
        fill(ctx, CGPath(roundedRect: CGRect(x: 0.26, y: 0.29, width: 0.46, height: 0.25),
                         cornerWidth: 0.12, cornerHeight: 0.12, transform: nil), t.fox, outline: t.foxDark)
        fill(ctx, ellipse(0.66, 0.39, 0.1, 0.13), t.foxLight)

        // Cabeza con orejas en punta y hocico largo.
        let head = polygon([(0.58, 0.50), (0.64, 0.66), (0.65, 0.84), (0.72, 0.70), (0.78, 0.82),
                            (0.80, 0.65), (0.95, 0.54), (0.86, 0.46), (0.66, 0.43)])
        fill(ctx, head, t.fox, outline: t.foxDark)
        // Interior oscuro de las orejas.
        fill(ctx, polygon([(0.655, 0.80), (0.66, 0.70), (0.70, 0.71)]), t.foxDark)
        fill(ctx, polygon([(0.775, 0.78), (0.74, 0.70), (0.785, 0.68)]), t.foxDark)
        // Mejilla y garganta claras.
        fill(ctx, polygon([(0.68, 0.45), (0.86, 0.465), (0.92, 0.52), (0.76, 0.53)]), t.foxLight)
        // Nariz y ojo.
        fill(ctx, ellipse(0.945, 0.535, 0.045, 0.045), t.foxDark)
        fill(ctx, ellipse(0.79, 0.595, 0.04, 0.04), t.foxDark)
    }

    private static func drawFront(_ ctx: CGContext, _ t: Theme) {
        shadow(ctx, t)

        // Cola enroscada a un lado.
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 0.62, y: 0.36))
        tailPath.addQuadCurve(to: CGPoint(x: 0.92, y: 0.30), control: CGPoint(x: 0.80, y: 0.52))
        tailPath.addQuadCurve(to: CGPoint(x: 0.62, y: 0.22), control: CGPoint(x: 0.82, y: 0.14))
        tailPath.closeSubpath()
        tail(ctx, tailPath, t, tipRect: CGRect(x: 0.84, y: 0, width: 0.2, height: 1))

        // Cuerpo sentado, pecho claro y patas delanteras.
        fill(ctx, ellipse(0.5, 0.33, 0.4, 0.32), t.fox, outline: t.foxDark)
        fill(ctx, ellipse(0.5, 0.35, 0.17, 0.22), t.foxLight)
        ctx.setFillColor(t.foxDark)
        for x in [0.395, 0.545] {
            ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: 0.13, width: 0.06, height: 0.14),
                               cornerWidth: 0.025, cornerHeight: 0.025, transform: nil))
        }
        ctx.fillPath()

        // Cabeza triangular.
        let head = polygon([(0.28, 0.88), (0.41, 0.72), (0.59, 0.72), (0.72, 0.88),
                            (0.71, 0.60), (0.5, 0.42), (0.29, 0.60)])
        fill(ctx, head, t.fox, outline: t.foxDark)
        fill(ctx, polygon([(0.31, 0.83), (0.33, 0.71), (0.40, 0.73)]), t.foxDark)
        fill(ctx, polygon([(0.69, 0.83), (0.67, 0.71), (0.60, 0.73)]), t.foxDark)
        // Hocico claro, nariz y ojos.
        fill(ctx, polygon([(0.38, 0.57), (0.62, 0.57), (0.5, 0.43)]), t.foxLight)
        fill(ctx, ellipse(0.5, 0.465, 0.07, 0.05), t.foxDark)
        fill(ctx, ellipse(0.415, 0.625, 0.045, 0.05), t.foxDark)
        fill(ctx, ellipse(0.585, 0.625, 0.045, 0.05), t.foxDark)
    }

    private static func drawBack(_ ctx: CGContext, _ t: Theme) {
        shadow(ctx, t)

        // Patas traseras.
        ctx.setFillColor(t.foxDark)
        for x in [0.33, 0.61] {
            ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: 0.15, width: 0.06, height: 0.14),
                               cornerWidth: 0.025, cornerHeight: 0.025, transform: nil))
        }
        ctx.fillPath()

        // Cuerpo.
        fill(ctx, ellipse(0.5, 0.42, 0.42, 0.34), t.fox, outline: t.foxDark)

        // Cabeza de espaldas con las orejas.
        let head = polygon([(0.31, 0.66), (0.33, 0.90), (0.44, 0.76), (0.56, 0.76), (0.67, 0.90),
                            (0.69, 0.66), (0.5, 0.55)])
        fill(ctx, head, t.fox, outline: t.foxDark)
        fill(ctx, polygon([(0.33, 0.90), (0.35, 0.80), (0.40, 0.81)]), t.foxDark)
        fill(ctx, polygon([(0.67, 0.90), (0.65, 0.80), (0.60, 0.81)]), t.foxDark)

        // Cola hacia el espectador, con la punta negra.
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 0.44, y: 0.32))
        tailPath.addQuadCurve(to: CGPoint(x: 0.5, y: 0.02), control: CGPoint(x: 0.34, y: 0.10))
        tailPath.addQuadCurve(to: CGPoint(x: 0.56, y: 0.32), control: CGPoint(x: 0.66, y: 0.10))
        tailPath.closeSubpath()
        tail(ctx, tailPath, t, tipRect: CGRect(x: 0, y: 0, width: 1, height: 0.1))
    }
}
