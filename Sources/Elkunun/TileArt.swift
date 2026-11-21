// © 2026 App-Zilla. Licencia MIT.

import CoreGraphics
import SpriteKit

/// Casillas y araucarias en pixel art de 16×16 (ver `PixelArt` y `Theme.pixelColor`).
enum TileArt {
    enum Kind: CaseIterable {
        case floor, floorAlt, wall, wallAlt, goal, goalAlt, box, boxOnGoal
        case araucaria, araucariaTall, araucariaYoung
    }

    static func texture(_ kind: Kind, theme: Theme) -> SKTexture {
        art(kind).texture { character in
            // Las casillas alternas del damero cambian un poco el tono del suelo o del muro.
            switch (kind, character) {
            case (.floorAlt, "F"), (.goalAlt, "F"): theme.floorAlt
            case (.wallAlt, "W"): theme.wallAlt
            default: theme.pixelColor(character)
            }
        }
    }

    static func art(_ kind: Kind) -> PixelArt {
        switch kind {
        case .floor, .floorAlt: floor
        case .goal, .goalAlt: goal
        case .wall, .wallAlt: wall
        case .box: box
        case .boxOnGoal: boxOnGoal
        case .araucaria: araucaria
        case .araucariaTall: araucariaTall
        case .araucariaYoung: araucariaYoung
        }
    }

    /// Rombo centrado en `c` con semidiagonal `r`.
    static func rhombus(_ c: CGPoint, _ r: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: c.x, y: c.y + r))
        p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        p.addLine(to: CGPoint(x: c.x, y: c.y - r))
        p.addLine(to: CGPoint(x: c.x - r, y: c.y))
        p.closeSubpath()
        return p
    }

    // MARK: - Casillas

    /// Suelo con junta de 1 píxel arriba y a la izquierda, y dos motas.
    static let floor = PixelArt([
        "EEEEEEEEEEEEEEEE",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFEFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFEFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
    ])

    /// Destino: rombo añil con un rombo pequeño en el centro.
    static let goal = PixelArt([
        "EEEEEEEEEEEEEEEE",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFGGFFFFFF",
        "EFFFFFFGFFGFFFFF",
        "EFFFFFGFFFFGFFFF",
        "EFFFFGFFFFFFGFFF",
        "EFFFGFFFGGFFFGFF",
        "EFFFGFFFGGFFFGFF",
        "EFFFFGFFFFFFGFFF",
        "EFFFFFGFFFFGFFFF",
        "EFFFFFFGFFGFFFFF",
        "EFFFFFFFGGFFFFFF",
        "EFFFFFFFFFFFFFFF",
        "EFFFFFFFFFFFFFFF",
    ])

    /// Muro: bloque con bisel (luz arriba a la izquierda, sombra abajo a la derecha) y un zigzag
    /// rojo con dos rombos, como un trozo de faja tejida.
    static let wall = PixelArt([
        "BBBBBBBBBBBBBBBB",
        "BHHHHHHHHHHHHHHH",
        "BHWWWWWWWWWWWWWS",
        "BHWWWWWWWWWWWWWS",
        "BHWWWWWWWWRWWWWS",
        "BHWWWWWWWRRRWWWS",
        "BHWWWRWWWWRWWWWS",
        "BHWWRRRWWWWWWWWS",
        "BHWRRWRRWWWWWRWS",
        "BHRRWWWRRWWWRRWS",
        "BHRWWWWWRRWRRWWS",
        "BHWWWRWWWRRRWWWS",
        "BHWWRRRWWWRWWWWS",
        "BHWWWRWWWWWWWWWS",
        "BHWWWWWWWWWWWWWS",
        "BHSSSSSSSSSSSSSS",
    ])

    /// Caja: un fardo tejido con bandas cruzadas.
    static let box = PixelArt([
        "................",
        "................",
        "...xxxxxxxxxx...",
        "..xLLLLLLLLLLx..",
        "..xXXLXXXXLXXxs.",
        "..xxxLxxxxLxxxs.",
        "..xXXLXXXXLXXxs.",
        "..xXXLXXXXLXXxs.",
        "..xXXLXXXXLXXxs.",
        "..xXXLXXXXLXXxs.",
        "..xxxLxxxxLxxxs.",
        "..xXXLXXXXLXXxs.",
        "..xXXLXXXXLXXxs.",
        "...xxxxxxxxxxss.",
        "....ssssssssss..",
        "................",
    ])

    /// Caja sobre su destino: roja con un rombo claro.
    static let boxOnGoal = PixelArt([
        "................",
        "................",
        "...xxxxxxxxxx...",
        "..xQQQQQQQQQQx..",
        "..xQQQQqqQQQQxs.",
        "..xQQQqQQqQQQxs.",
        "..xQQqQQQQqQQxs.",
        "..xQqQQqqQQqQxs.",
        "..xQqQQqqQQqQxs.",
        "..xQQqQQQQqQQxs.",
        "..xQQQqQQqQQQxs.",
        "..xQQQQqqQQQQxs.",
        "..xQQQQQQQQQQxs.",
        "...xxxxxxxxxxss.",
        "....ssssssssss..",
        "................",
    ])

    // MARK: - Araucarias

    /// Araucaria adulta (pehuén): copa en forma de paraguas, con los pisos de ramas
    /// curvados hacia arriba en las puntas.
    static let araucaria = PixelArt([
        "................",
        ".......tt.......",
        "....tTTTTTTt....",
        "...T..TNNT..T...",
        ".ttTTTTNNTTTTtt.",
        "T..TTTTTTTTTT..T",
        "..tt...NN...tt..",
        "..TTTTTNNTTTTT..",
        "..T..TTTTTT..T..",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".....ssNNss.....",
    ])

    /// Adulta alta: tronco largo y copa pequeña arriba.
    static let araucariaTall = PixelArt([
        "................",
        ".......tt.......",
        ".....tTTTTt.....",
        "...tT..NN..Tt...",
        "...TTTTNNTTTT...",
        "..t....NN....t..",
        "..TTTTTNNTTTTT..",
        "...TT..NN..TT...",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".....ssNNss.....",
    ])

    /// Joven: forma cónica, más ancha abajo.
    static let araucariaYoung = PixelArt([
        "................",
        ".......tt.......",
        "......tTTt......",
        ".......NN.......",
        ".....tTTTTt.....",
        "....tTTNNTTt....",
        ".......NN.......",
        "...tTTTTTTTTt...",
        "..tTTTTNNTTTTt..",
        ".......NN.......",
        ".tTTTTTTTTTTTTt.",
        "tTTTTTTNNTTTTTTt",
        ".......NN.......",
        ".......NN.......",
        ".......NN.......",
        ".....ssNNss.....",
    ])
}
