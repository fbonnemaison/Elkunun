// © 2026 App-Zilla. Licencia MIT.
// Genera los tamaños del icono de la app a partir del original en pixel art
// (Design/AppIcon-source.png): placa redondeada de la rejilla de iconos de macOS
// (824 px con 100 px de margen en 1024) y esquinas transparentes.
// Uso: Scripts/generate-icon.sh

import AppKit
let src = NSImage(contentsOfFile: CommandLine.arguments[1])!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let out = CommandLine.arguments[2]
for (name, px) in [("16x16",16),("16x16@2x",32),("32x32",32),("32x32@2x",64),("128x128",128),("128x128@2x",256),("256x256",256),("256x256@2x",512),("512x512",512),("512x512@2x",1024)] {
  let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  let k = CGFloat(px) / 1024
  let plate = CGRect(x: 100*k, y: 100*k, width: 824*k, height: 824*k)
  ctx.addPath(CGPath(roundedRect: plate, cornerWidth: 185*k, cornerHeight: 185*k, transform: nil)); ctx.clip()
  ctx.interpolationQuality = px >= 512 ? .none : .high
  // El original trae un borde negro fino: se recorta un 1,5 % por lado.
  let crop = plate.insetBy(dx: -plate.width*0.015, dy: -plate.height*0.015)
  ctx.draw(src, in: crop)
  let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
  try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/icon_\(name).png"))
}
