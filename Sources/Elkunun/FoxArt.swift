// © 2026 App-Zilla. Licencia MIT.

import CoreGraphics
import SpriteKit

/// El protagonista: un zorro culpeo (*Lycalopex culpaeus*) en pixel art de 16×16.
/// Pelaje rojizo, patas y punta de la cola oscuras, hocico y garganta claros.
/// Tres vistas: de lado (mirando a la derecha; a la izquierda se refleja), de frente y de espaldas.
/// La cola usa `o` y `k` para poder dibujarla aparte y menearla.
enum FoxArt {
    enum View {
        case side, front, back
    }

    /// Qué parte dibujar: todo junto (menús) o el cuerpo y la cola por separado,
    /// para que la escena pueda mover la cola.
    enum Part {
        case all, body, tail
    }

    /// Punto de giro de la cola (su base), en coordenadas unidad de la textura (y hacia arriba).
    static func tailPivot(_ view: View) -> CGPoint {
        switch view {
        case .side: CGPoint(x: 0.28, y: 0.5)
        case .front: CGPoint(x: 0.78, y: 0.25)
        case .back: CGPoint(x: 0.5, y: 0.31)
        }
    }

    /// `true` si la cola se dibuja delante del cuerpo (de espaldas, la cola mira al jugador).
    static func tailInFront(_ view: View) -> Bool { view == .back }

    static func image(_ view: View, theme: Theme, part: Part = .all) -> CGImage {
        art(view).makeImage { color($0, theme: theme, part: part) }
    }

    static func texture(_ view: View, theme: Theme, part: Part = .all) -> SKTexture {
        art(view).texture { color($0, theme: theme, part: part) }
    }

    private static func color(_ character: Character, theme: Theme, part: Part) -> CGColor? {
        let isTail = character == "o" || character == "k"
        switch part {
        case .all: return theme.pixelColor(character)
        case .body: return isTail ? nil : theme.pixelColor(character)
        case .tail: return isTail ? theme.pixelColor(character) : nil
        }
    }

    static func art(_ view: View) -> PixelArt {
        switch view {
        case .side: side
        case .front: front
        case .back: back
        }
    }

    static let side = PixelArt([
        "................",
        "................",
        "..........K..K..",
        ".........KOKKOK.",
        ".........KOOOOOK",
        ".........KOKOOOK",
        ".kkk.KKKKOOCCCCK",
        "kkooKOOOOOOCCKK.",
        "kkookOOOOOOOCCK.",
        ".kk.KOOOOOOOOOK.",
        "....KOOOOOOOOOK.",
        "....KKOKKKKKOKK.",
        ".....KK.....KK..",
        ".....K.K...K.K..",
        ".....K.K...K.K..",
        "....ssssssssss..",
    ])

    static let front = PixelArt([
        "................",
        "...K........K...",
        "...KK......KK...",
        "...KOKKKKKKOK...",
        "...KOOOOOOOOK...",
        "...KOKOOOOKOK...",
        "...KOOCCCCOOK...",
        "....KOCKKCOK....",
        ".....KKCCKK.....",
        "....KOOCCOOK....",
        "...KOOOCCOOOK.k.",
        "...KOOOCCOOOKkok",
        "...KOOOOOOOOKook",
        "...KOKOOOOKOKoo.",
        "...KKKKKKKKKKkk.",
        "...ssssssssss...",
    ])

    static let back = PixelArt([
        "................",
        "...K........K...",
        "...KK......KK...",
        "...KOKKKKKKOK...",
        "...KOOOOOOOOK...",
        "...KOOOOOOOOK...",
        "....KOOOOOOK....",
        ".....KOOOOK.....",
        "....KOOOOOOK....",
        "...KOOOOOOOOK...",
        "...KOOOOOOOOK...",
        "...KOOOkkOOOK...",
        "...KOOkookOOK...",
        "...KKKkookKKK...",
        "...K.KkookK.K...",
        "...sssskkssss...",
    ])
}
