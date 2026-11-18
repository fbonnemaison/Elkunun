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
        effect: rgb(0xF2EDE4)
    )

    static func forScheme(_ scheme: ColorScheme) -> Theme {
        scheme == .dark ? .dark : .light
    }

    private static func rgb(_ hex: UInt32) -> CGColor {
        CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }
}
