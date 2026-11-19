// © 2026 App-Zilla. Licencia MIT.

/// Partida en curso guardada para reanudarla al volver a abrir la app.
///
/// Solo se guarda el origen del nivel y los movimientos: al reanudar se vuelve a cargar el nivel
/// (de la campaña o regenerándolo desde su código) y se repiten los movimientos.
public struct SavedSession: Codable, Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case campaign(Int)
        case random(LevelCode)
    }

    public var source: Source
    /// Movimientos en notación de direcciones (`u`, `d`, `l`, `r`).
    public var moves: String
    public var hintsUsed: Int
    /// Tiempo de juego acumulado, en segundos.
    public var elapsedSeconds: Double

    public init(source: Source, moves: [Direction], hintsUsed: Int = 0, elapsedSeconds: Double = 0) {
        self.source = source
        self.moves = String(moves.map { $0.lurd(pushed: false) })
        self.hintsUsed = hintsUsed
        self.elapsedSeconds = elapsedSeconds
    }

    /// Movimientos como direcciones; `nil` si el texto guardado está dañado.
    public var directions: [Direction]? {
        var result: [Direction] = []
        for c in moves {
            guard let d = Direction(lurd: c) else { return nil }
            result.append(d)
        }
        return result
    }

    /// Repite los movimientos sobre `level`. Devuelve `nil` si alguno no es válido
    /// (por ejemplo, si el nivel cambió entre versiones).
    public func replay(on level: Level) -> GameState? {
        guard let directions else { return nil }
        var game = GameState(level: level)
        for d in directions {
            if game.move(d) == .blocked { return nil }
        }
        return game
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case campaign, code, moves, hintsUsed, elapsedSeconds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let index = try c.decodeIfPresent(Int.self, forKey: .campaign) {
            source = .campaign(index)
        } else if let text = try c.decodeIfPresent(String.self, forKey: .code), let code = LevelCode(text) {
            source = .random(code)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .campaign, in: c,
                                                   debugDescription: "Falta el origen del nivel")
        }
        moves = try c.decode(String.self, forKey: .moves)
        hintsUsed = try c.decodeIfPresent(Int.self, forKey: .hintsUsed) ?? 0
        elapsedSeconds = try c.decodeIfPresent(Double.self, forKey: .elapsedSeconds) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch source {
        case .campaign(let index): try c.encode(index, forKey: .campaign)
        case .random(let code): try c.encode(code.description, forKey: .code)
        }
        try c.encode(moves, forKey: .moves)
        try c.encode(hintsUsed, forKey: .hintsUsed)
        try c.encode(elapsedSeconds, forKey: .elapsedSeconds)
    }
}

extension Direction {
    /// Lee una letra LURD (mayúscula o minúscula).
    public init?(lurd: Character) {
        switch lurd.lowercased() {
        case "u": self = .up
        case "d": self = .down
        case "l": self = .left
        case "r": self = .right
        default: return nil
        }
    }
}
