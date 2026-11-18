// © 2026 App-Zilla. Licencia MIT.

import AppKit
import ElkunufeCore
import SpriteKit

/// Escena que dibuja y anima el tablero. Es dueña del `GameState` y avisa de cada cambio.
@MainActor
final class BoardScene: SKScene {
    // MARK: Estado

    private(set) var game: GameState
    /// Se llama tras cada cambio de estado (movimiento, deshacer, reinicio, nivel nuevo).
    var onChange: ((GameState) -> Void)?
    /// Se llama una vez al resolver el nivel.
    var onSolved: (() -> Void)?

    private var theme: Theme = .light

    // MARK: Nodos

    private let boardNode = SKNode()
    private let tileLayer = SKNode()
    private let pieceLayer = SKNode()
    private let effectLayer = SKNode()
    private var boxNodes: [Position: SKSpriteNode] = [:]
    private let fox = SKSpriteNode()
    private var facing: Direction = .down

    // MARK: Geometría

    /// Casillas dentro de la habitación (alcanzables desde el jugador sin atravesar muros).
    private var interior: Set<Position> = []
    private var tileSize: CGFloat = 48
    private var pixelSize = 0
    private var textures: [TileArt.Kind: SKTexture] = [:]
    private var foxTextures: [FoxArt.View: SKTexture] = [:]

    private var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    // MARK: - Ciclo de vida

    init(level: Level) {
        game = GameState(level: level)
        super.init(size: CGSize(width: 800, height: 600))
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        boardNode.addChild(tileLayer)
        boardNode.addChild(pieceLayer)
        boardNode.addChild(effectLayer)
        addChild(boardNode)
        computeInterior()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func didMove(to view: SKView) {
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil, size != oldSize else { return }
        rebuild()
    }

    func setTheme(_ newTheme: Theme) {
        guard newTheme != theme else { return }
        theme = newTheme
        textures = [:]
        foxTextures = [:]
        pixelSize = 0
        rebuild()
    }

    // MARK: - API del juego

    func load(_ level: Level) {
        game = GameState(level: level)
        facing = .down
        computeInterior()
        rebuild()
        onChange?(game)
    }

    func move(_ direction: Direction) {
        let wasSolved = game.isSolved
        let from = game.player
        let result = game.move(direction)
        facing = direction
        fox.texture = foxTexture(for: direction)
        fox.xScale = direction == .left ? -abs(fox.xScale) : abs(fox.xScale)

        switch result {
        case .blocked:
            bump(direction)
            return
        case .moved:
            animateFox(from: from, to: game.player, pushing: false)
        case .pushed:
            let boxFrom = game.player
            let boxTo = boxFrom.moved(direction)
            if let node = boxNodes.removeValue(forKey: boxFrom) {
                boxNodes[boxTo] = node
                let onGoal = game.board.isGoal(boxTo)
                let wasOnGoal = game.board.isGoal(boxFrom)
                node.removeAllActions()
                node.run(.sequence([
                    .move(to: point(boxTo), duration: stepDuration),
                    .run { [weak self] in
                        guard let self else { return }
                        node.texture = self.texture(onGoal ? .boxOnGoal : .box)
                        if onGoal && !wasOnGoal { self.celebrateBox(node) }
                    },
                ]))
            }
            animateFox(from: from, to: game.player, pushing: true)
        }
        onChange?(game)
        if game.isSolved && !wasSolved {
            run(.wait(forDuration: stepDuration)) { [weak self] in
                self?.celebrateLevel()
                self?.onSolved?()
            }
        }
    }

    func undo() {
        guard game.undo() else { return }
        syncPieces(animated: true)
        onChange?(game)
    }

    func redo() {
        guard game.redo() else { return }
        syncPieces(animated: true)
        onChange?(game)
    }

    func restart() {
        game.restart()
        facing = .down
        syncPieces(animated: false)
        onChange?(game)
    }

    // MARK: - Construcción

    private var stepDuration: TimeInterval { reduceMotion ? 0.05 : 0.12 }

    /// Tamaño máximo de casilla en puntos, para que los niveles pequeños no se vean gigantes.
    private static let maxTileSize: CGFloat = 72

    private func computeInterior() {
        var seen: Set<Position> = [game.player]
        var stack = [game.player]
        while let p = stack.popLast() {
            for d in Direction.allCases {
                let n = p.moved(d)
                if !game.board.isWall(n), game.board.contains(n), seen.insert(n).inserted { stack.append(n) }
            }
        }
        interior = seen
    }

    /// Recalcula tamaño de casilla y texturas, y vuelve a crear todos los nodos.
    private func rebuild() {
        backgroundColor = NSColor(cgColor: theme.background) ?? .black
        let board = game.board
        let margin: CGFloat = 0.92
        let fit = min(size.width / CGFloat(board.width), size.height / CGFloat(board.height)) * margin
        tileSize = max(8, floor(min(fit, Self.maxTileSize)))
        let scale = view?.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        // Redondeo a múltiplos de 16 px para no regenerar texturas en cada pequeño cambio de tamaño.
        let pixels = max(32, Int((tileSize * scale / 16).rounded(.up)) * 16)
        if pixels != pixelSize {
            pixelSize = pixels
            textures = [:]
            foxTextures = [:]
        }

        tileLayer.removeAllChildren()
        pieceLayer.removeAllChildren()
        effectLayer.removeAllChildren()
        boxNodes = [:]

        for p in board.positions {
            if interior.contains(p) {
                addTile(board.isGoal(p) ? .goal : .floor, at: p, z: 0)
            } else if board.isWall(p), touchesInterior(p) {
                addTile(.wall, at: p, z: 1)
            }
        }

        for b in game.boxes {
            let node = SKSpriteNode(texture: texture(board.isGoal(b) ? .boxOnGoal : .box))
            node.size = CGSize(width: tileSize, height: tileSize)
            node.position = point(b)
            node.zPosition = 2
            pieceLayer.addChild(node)
            boxNodes[b] = node
        }

        fox.removeAllActions()
        fox.removeFromParent()
        fox.texture = foxTexture(for: facing)
        fox.size = CGSize(width: tileSize * 1.08, height: tileSize * 1.08)
        fox.xScale = facing == .left ? -1 : 1
        fox.yScale = 1
        fox.position = point(game.player)
        fox.zPosition = 3
        pieceLayer.addChild(fox)
        startIdle()
    }

    private func addTile(_ kind: TileArt.Kind, at p: Position, z: CGFloat) {
        let node = SKSpriteNode(texture: texture(kind))
        // Un poco más grande para evitar costuras entre casillas al escalar.
        node.size = CGSize(width: tileSize + 0.5, height: tileSize + 0.5)
        node.position = point(p)
        node.zPosition = z
        tileLayer.addChild(node)
    }

    private func touchesInterior(_ p: Position) -> Bool {
        for dy in -1...1 {
            for dx in -1...1 where interior.contains(Position(x: p.x + dx, y: p.y + dy)) {
                return true
            }
        }
        return false
    }

    /// Centro de la casilla en coordenadas de la escena (y hacia arriba, origen en el centro).
    private func point(_ p: Position) -> CGPoint {
        let board = game.board
        return CGPoint(x: (CGFloat(p.x) + 0.5 - CGFloat(board.width) / 2) * tileSize,
                       y: (CGFloat(board.height) / 2 - CGFloat(p.y) - 0.5) * tileSize)
    }

    private func texture(_ kind: TileArt.Kind) -> SKTexture {
        if let t = textures[kind] { return t }
        let t = TileArt.texture(kind, theme: theme, pixels: pixelSize)
        textures[kind] = t
        return t
    }

    private func foxTexture(for direction: Direction) -> SKTexture {
        let view: FoxArt.View = switch direction {
        case .up: .back
        case .down: .front
        case .left, .right: .side
        }
        if let t = foxTextures[view] { return t }
        let t = FoxArt.texture(view, theme: theme, pixels: pixelSize)
        foxTextures[view] = t
        return t
    }

    // MARK: - Animaciones

    private func startIdle() {
        guard !reduceMotion else { return }
        let breathe = SKAction.sequence([
            .scaleY(to: 1.035, duration: 0.9),
            .scaleY(to: 1.0, duration: 0.9),
        ])
        breathe.timingMode = .easeInEaseOut
        fox.run(.repeatForever(breathe), withKey: "idle")
    }

    private func animateFox(from: Position, to: Position, pushing: Bool) {
        fox.removeAllActions()
        fox.position = point(from)
        fox.yScale = 1
        let moveAction = SKAction.move(to: point(to), duration: stepDuration)
        moveAction.timingMode = .easeOut
        guard !reduceMotion else {
            fox.run(moveAction)
            return
        }
        // Paso: un pequeño salto; empuje: se agacha y se estira hacia delante.
        let half = stepDuration / 2
        let bounce: SKAction = pushing
            ? .sequence([.scaleY(to: 0.9, duration: half), .scaleY(to: 1.0, duration: half)])
            : .sequence([.scaleY(to: 0.94, duration: half), .scaleY(to: 1.0, duration: half)])
        fox.run(.group([moveAction, bounce])) { [weak self] in
            self?.startIdle()
        }
    }

    /// Choque contra un muro o una caja inmovible: pequeño empujón y vuelta.
    private func bump(_ direction: Direction) {
        fox.removeAllActions()
        let home = point(game.player)
        fox.position = home
        fox.yScale = 1
        guard !reduceMotion else { return }
        let d = tileSize * 0.08
        let offset = CGVector(dx: CGFloat(direction.dx) * d, dy: -CGFloat(direction.dy) * d)
        fox.run(.sequence([
            .move(by: offset, duration: 0.05),
            .move(to: home, duration: 0.08),
        ])) { [weak self] in
            self?.startIdle()
        }
    }

    /// Coloca todas las piezas según el estado actual (tras deshacer, rehacer o reiniciar).
    private func syncPieces(animated: Bool) {
        let duration = animated ? stepDuration * 0.8 : 0
        // Reasignar nodos de cajas: las que no se movieron se quedan; el resto se empareja con las nuevas posiciones.
        let target = game.boxes
        var remaining = boxNodes.filter { !target.contains($0.key) }.map(\.value)
        var newMap: [Position: SKSpriteNode] = [:]
        for b in target {
            if let node = boxNodes[b] {
                newMap[b] = node
            } else if let node = remaining.popLast() {
                newMap[b] = node
            }
        }
        boxNodes = newMap
        for (p, node) in boxNodes {
            node.removeAllActions()
            node.setScale(1)
            node.texture = texture(game.board.isGoal(p) ? .boxOnGoal : .box)
            node.run(.move(to: point(p), duration: duration))
        }

        if let last = game.history.last?.direction { facing = last }
        fox.removeAllActions()
        fox.texture = foxTexture(for: facing)
        fox.xScale = facing == .left ? -1 : 1
        fox.yScale = 1
        fox.run(.move(to: point(game.player), duration: duration)) { [weak self] in
            self?.startIdle()
        }
        effectLayer.removeAllChildren()
    }

    // MARK: - Efectos

    /// Caja colocada en su destino: latido y chispas en forma de rombo.
    private func celebrateBox(_ node: SKSpriteNode) {
        guard !reduceMotion else { return }
        node.run(.sequence([.scale(to: 1.12, duration: 0.08), .scale(to: 1.0, duration: 0.12)]))
        burst(at: node.position, count: 6, radius: tileSize * 0.7)
    }

    /// Nivel resuelto: las cajas laten en ola y el zorro salta.
    private func celebrateLevel() {
        guard !reduceMotion else { return }
        let ordered = boxNodes.sorted { ($0.key.y, $0.key.x) < ($1.key.y, $1.key.x) }
        for (i, (_, node)) in ordered.enumerated() {
            node.run(.sequence([
                .wait(forDuration: Double(i) * 0.08),
                .scale(to: 1.15, duration: 0.1),
                .scale(to: 1.0, duration: 0.15),
            ]))
            burst(at: node.position, count: 8, radius: tileSize)
        }
        fox.removeAllActions()
        let hop = SKAction.sequence([
            .moveBy(x: 0, y: tileSize * 0.25, duration: 0.12),
            .moveBy(x: 0, y: -tileSize * 0.25, duration: 0.12),
        ])
        hop.timingMode = .easeInEaseOut
        fox.texture = foxTexture(for: .down)
        fox.xScale = 1
        fox.run(.sequence([.repeat(hop, count: 2)])) { [weak self] in
            self?.startIdle()
        }
    }

    private func burst(at center: CGPoint, count: Int, radius: CGFloat) {
        for i in 0..<count {
            let angle = CGFloat(i) / CGFloat(count) * 2 * .pi
            let spark = SKShapeNode(path: TileArt.rhombus(.zero, tileSize * 0.08))
            spark.fillColor = NSColor(cgColor: theme.effect) ?? .red
            spark.strokeColor = .clear
            spark.position = center
            spark.zPosition = 10
            effectLayer.addChild(spark)
            let move = SKAction.move(by: CGVector(dx: cos(angle) * radius, dy: sin(angle) * radius), duration: 0.35)
            move.timingMode = .easeOut
            spark.run(.sequence([.group([move, .fadeOut(withDuration: 0.35)]), .removeFromParent()]))
        }
    }
}
