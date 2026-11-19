// © 2026 App-Zilla. Licencia MIT.
// Dibuja el icono de la app (estilo «gradiente»: zorro culpeo facetado sobre fondo rojo-anaranjado,
// con la caja roja del juego) y lo guarda en AppIcon.appiconset.
// Uso: Scripts/generate-icon.sh

import AppKit
import SpriteKit

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
                 : "Sources/Elkunun/Assets.xcassets/AppIcon.appiconset")

// MARK: - Colores

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let bgTop = rgb(0xE9445A)        // rojo rosado
let bgBottom = rgb(0xF2803A)     // naranja
let furLight = rgb(0xF7A24B)
let furMid = rgb(0xEC7F2C)
let furDark = rgb(0xD9631E)
let cream = rgb(0xFCEBD2)
let creamShade = rgb(0xEFD3B0)
let brown = rgb(0x4A2A1C)
let brownLight = rgb(0x6B3B25)
let ink = rgb(0x2E1A12)
let gemLight = rgb(0xFF6B6B)
let gemMid = rgb(0xE5263A)
let gemDark = rgb(0xA90F25)

// MARK: - Utilidades

func poly(_ points: [(CGFloat, CGFloat)]) -> CGPath {
    let p = CGMutablePath()
    p.addLines(between: points.map { CGPoint(x: $0.0, y: $0.1) })
    p.closeSubpath()
    return p
}

func fill(_ ctx: CGContext, _ path: CGPath, _ color: CGColor) {
    ctx.setFillColor(color)
    ctx.addPath(path)
    ctx.fillPath()
}

/// Brillo suave en los bordes de las facetas, como en la referencia.
func edge(_ ctx: CGContext, _ path: CGPath, alpha: CGFloat = 0.55, width: CGFloat = 0.004) {
    ctx.setStrokeColor(rgb(0xFFD08A, alpha))
    ctx.setLineWidth(width)
    ctx.setLineJoin(.round)
    ctx.addPath(path)
    ctx.strokePath()
}

func radialGlow(_ ctx: CGContext, center: CGPoint, radius: CGFloat, color: CGColor) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let clear = color.copy(alpha: 0)!
    let gradient = CGGradient(colorsSpace: space, colors: [color, clear] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                           endRadius: radius, options: [])
}

/// Destello de cuatro puntas.
func sparkle(_ ctx: CGContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, alpha: CGFloat) {
    let p = CGMutablePath()
    let k = r * 0.22
    p.addLines(between: [CGPoint(x: x, y: y + r), CGPoint(x: x + k, y: y + k), CGPoint(x: x + r, y: y),
                         CGPoint(x: x + k, y: y - k), CGPoint(x: x, y: y - r), CGPoint(x: x - k, y: y - k),
                         CGPoint(x: x - r, y: y), CGPoint(x: x - k, y: y + k)])
    p.closeSubpath()
    fill(ctx, p, rgb(0xFFF1D6, alpha))
}

// MARK: - Icono

/// Icono de 1024×1024: placa redondeada (rejilla de iconos de macOS: 824 px con 100 px de margen).
func drawIcon(pixels: Int) -> CGImage {
    TileArt.render(pixels: pixels) { ctx in
        let inset = 100.0 / 1024
        let plate = CGRect(x: inset, y: inset + 0.01, width: 1 - 2 * inset, height: 1 - 2 * inset)
        let radius = plate.width * 0.225
        let shape = CGPath(roundedRect: plate, cornerWidth: radius, cornerHeight: radius, transform: nil)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!

        // Sombra de la placa.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -0.012), blur: 0.03, color: CGColor(gray: 0, alpha: 0.35))
        fill(ctx, shape, bgTop)
        ctx.restoreGState()

        ctx.saveGState()
        ctx.addPath(shape)
        ctx.clip()

        // Fondo en degradado: rojo rosado arriba a la izquierda, naranja abajo a la derecha.
        let bg = CGGradient(colorsSpace: space, colors: [bgTop, bgBottom] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(bg, start: CGPoint(x: plate.minX, y: plate.maxY),
                               end: CGPoint(x: plate.maxX, y: plate.minY), options: [])
        // Resplandor cálido detrás del zorro.
        radialGlow(ctx, center: CGPoint(x: 0.47, y: 0.47), radius: 0.38, color: rgb(0xFFC060, 0.55))

        // Caja roja del juego (una caja ya guardada en su destino), facetada y con brillo.
        drawStoredBox(ctx, center: CGPoint(x: 0.75, y: 0.69), size: 0.175)

        // Destellos.
        for (x, y, r, a) in [(0.84, 0.82, 0.022, 0.9), (0.66, 0.83, 0.012, 0.7), (0.22, 0.47, 0.014, 0.6),
                             (0.83, 0.55, 0.011, 0.6), (0.25, 0.80, 0.010, 0.5)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
            sparkle(ctx, x, y, r, alpha: a)
        }

        // Sombra bajo el zorro.
        fill(ctx, CGPath(ellipseIn: CGRect(x: 0.25, y: 0.165, width: 0.52, height: 0.06), transform: nil),
             rgb(0x8A2A10, 0.28))

        drawFox(ctx)
        ctx.restoreGState()

        // Borde fino y brillo superior de la placa.
        ctx.setStrokeColor(rgb(0xFFFFFF, 0.18))
        ctx.setLineWidth(0.004)
        ctx.addPath(shape)
        ctx.strokePath()
    }
}

/// La caja guardada del juego (roja, borde oscuro, rombo blanco con rombo rojo dentro) en el
/// mismo estilo facetado del zorro: mitad clara arriba a la izquierda, mitad oscura abajo a la
/// derecha, bordes con brillo y un resplandor detrás.
func drawStoredBox(_ ctx: CGContext, center c: CGPoint, size: CGFloat) {
    radialGlow(ctx, center: c, radius: size * 1.05, color: rgb(0xFFB3A0, 0.75))

    let rect = CGRect(x: c.x - size / 2, y: c.y - size / 2, width: size, height: size)
    let corner = size * 0.14
    let outer = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // Sombra suave.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.06), blur: size * 0.12, color: rgb(0x7A1A10, 0.45))
    fill(ctx, outer, rgb(0x6E2216))
    ctx.restoreGState()

    // Marco oscuro (como el borde de la caja en el juego) y cara roja con dos facetas.
    let face = rect.insetBy(dx: size * 0.075, dy: size * 0.075)
    let faceCorner = size * 0.09
    let facePath = CGPath(roundedRect: face, cornerWidth: faceCorner, cornerHeight: faceCorner, transform: nil)
    fill(ctx, facePath, gemMid)
    ctx.saveGState()
    ctx.addPath(facePath)
    ctx.clip()
    fill(ctx, poly([(face.minX, face.maxY), (face.maxX, face.maxY), (face.minX, face.minY)]), gemLight)
    fill(ctx, poly([(face.maxX, face.maxY), (face.maxX, face.minY), (face.minX, face.minY)]), gemDark.copy(alpha: 0.55)!)
    ctx.restoreGState()

    // Rombo blanco (claro a la izquierda, crema sombreado a la derecha).
    let r = size * 0.3
    fill(ctx, poly([(c.x, c.y + r), (c.x, c.y - r), (c.x - r, c.y)]), cream)
    fill(ctx, poly([(c.x, c.y + r), (c.x + r, c.y), (c.x, c.y - r)]), creamShade)
    // Rombo rojo interior, también en dos facetas, y su punto central.
    let r2 = r * 0.55
    fill(ctx, poly([(c.x, c.y + r2), (c.x, c.y - r2), (c.x - r2, c.y)]), gemLight)
    fill(ctx, poly([(c.x, c.y + r2), (c.x + r2, c.y), (c.x, c.y - r2)]), gemMid)
    let r3 = r * 0.2
    fill(ctx, poly([(c.x, c.y + r3), (c.x + r3, c.y), (c.x, c.y - r3), (c.x - r3, c.y)]), cream)

    // Brillos en los bordes.
    edge(ctx, outer, alpha: 0.6, width: 0.004)
    edge(ctx, poly([(c.x, c.y + r), (c.x + r, c.y), (c.x, c.y - r), (c.x - r, c.y)]), alpha: 0.5, width: 0.003)
}

/// Zorro culpeo sentado de frente, facetado: pelaje anaranjado, pecho y mejillas claros,
/// patas y orejas oscuras, y la cola con la punta negra.
func drawFox(_ ctx: CGContext) {
    // Cola: barre hacia la derecha y sube, con la punta negra.
    let tail = CGMutablePath()
    tail.move(to: CGPoint(x: 0.55, y: 0.205))
    tail.addQuadCurve(to: CGPoint(x: 0.80, y: 0.30), control: CGPoint(x: 0.76, y: 0.15))
    tail.addQuadCurve(to: CGPoint(x: 0.735, y: 0.555), control: CGPoint(x: 0.86, y: 0.47))
    tail.addQuadCurve(to: CGPoint(x: 0.60, y: 0.33), control: CGPoint(x: 0.67, y: 0.40))
    tail.closeSubpath()
    fill(ctx, tail, furMid)
    ctx.saveGState()
    ctx.addPath(tail)
    ctx.clip()
    // Faceta clara a lo largo de la cola.
    fill(ctx, poly([(0.58, 0.25), (0.78, 0.29), (0.74, 0.50), (0.66, 0.36)]), furLight)
    // Base de la cola, más oscura.
    fill(ctx, poly([(0.50, 0.15), (0.66, 0.15), (0.64, 0.27), (0.55, 0.29)]), furDark)
    // Punta negra (rasgo del culpeo).
    fill(ctx, CGPath(ellipseIn: CGRect(x: 0.68, y: 0.47, width: 0.12, height: 0.12), transform: nil), brown)
    ctx.restoreGState()
    edge(ctx, tail)

    // Cuerpo sentado: dos facetas (luz a la izquierda).
    let body = poly([(0.355, 0.47), (0.545, 0.47), (0.605, 0.31), (0.58, 0.195), (0.32, 0.195), (0.295, 0.31)])
    fill(ctx, body, furMid)
    fill(ctx, poly([(0.355, 0.47), (0.45, 0.47), (0.45, 0.195), (0.32, 0.195), (0.295, 0.31)]), furLight)
    fill(ctx, poly([(0.545, 0.47), (0.605, 0.31), (0.58, 0.195), (0.52, 0.195)]), furDark)
    // Pecho claro en V.
    fill(ctx, poly([(0.37, 0.465), (0.53, 0.465), (0.45, 0.25)]), cream)
    fill(ctx, poly([(0.45, 0.465), (0.53, 0.465), (0.45, 0.25)]), creamShade)
    edge(ctx, body)

    // Ancas y patas delanteras oscuras.
    fill(ctx, poly([(0.295, 0.31), (0.335, 0.30), (0.355, 0.195), (0.32, 0.195)]), brownLight)
    fill(ctx, poly([(0.605, 0.31), (0.565, 0.30), (0.545, 0.195), (0.58, 0.195)]), brownLight)
    for x in [0.388, 0.462] as [CGFloat] {
        fill(ctx, CGPath(roundedRect: CGRect(x: x, y: 0.19, width: 0.05, height: 0.14),
                         cornerWidth: 0.025, cornerHeight: 0.025, transform: nil), brown)
    }

    // Orejas: borde oscuro e interior claro.
    for (outer, inner) in [
        (poly([(0.285, 0.62), (0.30, 0.81), (0.415, 0.665)]), poly([(0.31, 0.64), (0.315, 0.765), (0.385, 0.67)])),
        (poly([(0.615, 0.62), (0.60, 0.81), (0.485, 0.665)]), poly([(0.59, 0.64), (0.585, 0.765), (0.515, 0.67)])),
    ] {
        fill(ctx, outer, brown)
        fill(ctx, inner, cream)
    }

    // Cabeza ancha en triángulo invertido, con dos facetas.
    let head = poly([(0.245, 0.565), (0.29, 0.655), (0.45, 0.675), (0.61, 0.655), (0.655, 0.565), (0.45, 0.425)])
    fill(ctx, head, furMid)
    fill(ctx, poly([(0.245, 0.565), (0.29, 0.655), (0.45, 0.675), (0.45, 0.425)]), furLight)
    // Mejillas y hocico claros.
    fill(ctx, poly([(0.245, 0.565), (0.36, 0.535), (0.45, 0.47), (0.54, 0.535), (0.655, 0.565), (0.45, 0.425)]), cream)
    fill(ctx, poly([(0.45, 0.47), (0.54, 0.535), (0.655, 0.565), (0.45, 0.425)]), creamShade)
    edge(ctx, head)

    // Ojos y nariz.
    for x in [0.385, 0.515] as [CGFloat] {
        fill(ctx, CGPath(ellipseIn: CGRect(x: x - 0.017, y: 0.555, width: 0.034, height: 0.046), transform: nil), ink)
        fill(ctx, CGPath(ellipseIn: CGRect(x: x - 0.004, y: 0.584, width: 0.009, height: 0.009), transform: nil),
             rgb(0xFFFFFF, 0.85))
    }
    fill(ctx, poly([(0.425, 0.495), (0.475, 0.495), (0.45, 0.462)]), ink)
}

// MARK: - Salida

let sizes: [(points: Int, scale: Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
                                          (256, 1), (256, 2), (512, 1), (512, 2)]
var images: [String] = []
for (points, scale) in sizes {
    let pixels = points * scale
    let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
    let rep = NSBitmapImageRep(cgImage: drawIcon(pixels: pixels))
    try! rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
    images.append("""
        { "filename" : "\(name)", "idiom" : "mac", "scale" : "\(scale)x", "size" : "\(points)x\(points)" }
    """)
}
let json = """
{
  "images" : [
\(images.joined(separator: ",\n"))
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}

"""
try! json.write(to: output.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Icono escrito en \(output.path)")
