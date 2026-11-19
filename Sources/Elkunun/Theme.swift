// © 2026 App-Zilla. Licencia MIT.

import AppKit
import SwiftUI

/// Colores del tablero para modo claro y oscuro.
/// Inspirados en los textiles mapuches: rojo, negro, blanco de lana cruda y añil.
struct Theme: Equatable {
    let background: CGColor
    let floor: CGColor
    let floorEdge: CGColor
    let wall: CGColor
    let wallAccent: CGColor
    let goal: CGColor
    let box: CGColor
    let boxDark: CGColor
    let boxLight: CGColor
    let boxOnGoal: CGColor
    let boxOnGoalAccent: CGColor
    let fox: CGColor
    let foxDark: CGColor
    let foxLight: CGColor
    let effect: CGColor
    /// Araucarias: verde oscuro de las ramas, verde claro de los brillos y tronco.
    var treeDark: CGColor = rgb(0x24573A)
    var treeLight: CGColor = rgb(0x4C8F5C)
    var trunk: CGColor = rgb(0x6B4A33)

    static let light = Theme(
        background: rgb(0xE6DDCF),
        floor: rgb(0xF6F1E8),
        floorEdge: rgb(0xE3D9C8),
        wall: rgb(0x1E1A1B),
        wallAccent: rgb(0xB0242D),
        goal: rgb(0x2A3B6B),
        box: rgb(0xC48A45),
        boxDark: rgb(0x7E5126),
        boxLight: rgb(0xE2B377),
        boxOnGoal: rgb(0xB0242D),
        boxOnGoalAccent: rgb(0xF6F1E8),
        fox: rgb(0xC9612B),
        foxDark: rgb(0x2B2220),
        foxLight: rgb(0xF3E4CC),
        effect: rgb(0xB0242D)
    )

    static let dark = Theme(
        background: rgb(0x10142A),
        floor: rgb(0x262D4A),
        floorEdge: rgb(0x1D2340),
        wall: rgb(0x08080C),
        wallAccent: rgb(0x9A2630),
        goal: rgb(0x9BB0EE),
        box: rgb(0xB27B3C),
        boxDark: rgb(0x6A4420),
        boxLight: rgb(0xD5A368),
        boxOnGoal: rgb(0xC3303B),
        boxOnGoalAccent: rgb(0xF2EDE4),
        fox: rgb(0xD06A33),
        foxDark: rgb(0x1E1817),
        foxLight: rgb(0xF0E2CB),
        effect: rgb(0xF2EDE4),
        treeDark: rgb(0x1C4A31),
        treeLight: rgb(0x3E7E52),
        trunk: rgb(0x5A3D2A)
    )

    /// Alto contraste claro: suelo blanco, muros negros, contornos marcados.
    static let highContrastLight = Theme(
        background: rgb(0xFFFFFF),
        floor: rgb(0xFFFFFF),
        floorEdge: rgb(0x8A8A8A),
        wall: rgb(0x000000),
        wallAccent: rgb(0xD0101C),
        goal: rgb(0x0030C0),
        box: rgb(0xE0A030),
        boxDark: rgb(0x000000),
        boxLight: rgb(0xFFE0A0),
        boxOnGoal: rgb(0xD0101C),
        boxOnGoalAccent: rgb(0xFFFFFF),
        fox: rgb(0xD05010),
        foxDark: rgb(0x000000),
        foxLight: rgb(0xFFFFFF),
        effect: rgb(0xD0101C)
    )

    /// Alto contraste oscuro: suelo negro, muros grises, colores saturados.
    static let highContrastDark = Theme(
        background: rgb(0x000000),
        floor: rgb(0x000000),
        floorEdge: rgb(0x707070),
        wall: rgb(0x5A5A5A),
        wallAccent: rgb(0xFF4050),
        goal: rgb(0x60A0FF),
        box: rgb(0xF0B040),
        boxDark: rgb(0xFFFFFF),
        boxLight: rgb(0xFFE6B0),
        boxOnGoal: rgb(0xFF3040),
        boxOnGoalAccent: rgb(0xFFFFFF),
        fox: rgb(0xFF7030),
        foxDark: rgb(0xFFFFFF),
        foxLight: rgb(0xFFFFFF),
        effect: rgb(0xFFFFFF)
    )

    /// Color de las casillas alternas del damero: el suelo mezclado un poco con su borde,
    /// para que la diferencia sea tenue.
    var floorAlt: CGColor {
        let a = floor.components ?? [0, 0, 0, 1]
        let b = floorEdge.components ?? a
        let t: CGFloat = 0.4
        return CGColor(srgbRed: a[0] + (b[0] - a[0]) * t,
                       green: a[1] + (b[1] - a[1]) * t,
                       blue: a[2] + (b[2] - a[2]) * t,
                       alpha: 1)
    }

    /// Color de los bloques de muro alternos del damero: el muro un poco aclarado, para que la
    /// diferencia sea tenue (como el suelo).
    var wallAlt: CGColor {
        let a = wall.components ?? [0, 0, 0, 1]
        let t: CGFloat = 0.09
        return CGColor(srgbRed: a[0] + (1 - a[0]) * t,
                       green: a[1] + (1 - a[1]) * t,
                       blue: a[2] + (1 - a[2]) * t,
                       alpha: 1)
    }

    /// Tema según el modo de color y el contraste pedido (ajuste propio o el de Accesibilidad de macOS).
    static func current(_ scheme: ColorScheme, highContrast: Bool) -> Theme {
        let contrast = highContrast || NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        switch (scheme == .dark, contrast) {
        case (false, false): return .light
        case (true, false): return .dark
        case (false, true): return .highContrastLight
        case (true, true): return .highContrastDark
        }
    }

    static func rgb(_ hex: UInt32) -> CGColor {
        CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }
}
