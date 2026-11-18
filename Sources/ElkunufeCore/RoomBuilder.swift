// © 2026 App-Zilla. Licencia MIT.

/// Construye la forma de una habitación combinando bloques de 3×3 elegidos al azar.
///
/// Idea basada en el método de plantillas descrito por Taylor y Parberry (2011) para
/// generar niveles del género. Las plantillas de este archivo son propias.
struct RoomBuilder {
    /// Plantillas de 3×3: `#` muro, `.` suelo.
    static let templates: [[String]] = [
        ["...", "...", "..."],
        ["#..", "...", "..."],
        ["##.", "#..", "..."],
        ["...", ".#.", "..."],
        ["#..", "#..", "..."],
        ["...", "###", "..."],
        ["#.#", "...", "#.#"],
        [".#.", "...", "..."],
        ["..#", "...", "#.."],
        ["##.", "...", "..."],
        ["...", ".#.", ".#."],
        ["###", "...", "..."],
        ["#..", "...", "..#"],
    ]

    /// Suelo de la habitación (sin el borde exterior), por filas: `true` = suelo.
    struct Room {
        let width: Int
        let height: Int
        var floor: [Bool]

        func isFloor(_ x: Int, _ y: Int) -> Bool {
            x >= 0 && y >= 0 && x < width && y < height && floor[y * width + x]
        }

        var floorCount: Int { floor.count(where: { $0 }) }
    }

    /// Intenta construir una habitación de `blocksWide × blocksHigh` bloques.
    /// Devuelve `nil` si la forma resultante no es aceptable.
    static func build(blocksWide: Int, blocksHigh: Int, minFloor: Int, rng: inout SeededRandom) -> Room? {
        let width = blocksWide * 3
        let height = blocksHigh * 3
        var room = Room(width: width, height: height, floor: [Bool](repeating: false, count: width * height))

        for by in 0..<blocksHigh {
            for bx in 0..<blocksWide {
                var cells = rng.element(of: templates).map { Array($0).map { $0 == "." } }
                for _ in 0..<rng.int(below: 4) { cells = rotate(cells) }
                if rng.chance(50) { cells = cells.map { $0.reversed() } }
                for y in 0..<3 {
                    for x in 0..<3 {
                        room.floor[(by * 3 + y) * width + bx * 3 + x] = cells[y][x]
                    }
                }
            }
        }

        fillDeadEnds(&room)
        keepLargestRegion(&room)
        guard room.floorCount >= minFloor, !hasOpenArea(room) else { return nil }
        return cropped(room)
    }

    /// Recorta filas y columnas sin suelo de los bordes.
    private static func cropped(_ room: Room) -> Room {
        let xs = room.floor.indices.filter { room.floor[$0] }.map { $0 % room.width }
        let ys = room.floor.indices.filter { room.floor[$0] }.map { $0 / room.width }
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else { return room }
        let width = maxX - minX + 1
        let height = maxY - minY + 1
        var floor = [Bool](repeating: false, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                floor[y * width + x] = room.isFloor(x + minX, y + minY)
            }
        }
        return Room(width: width, height: height, floor: floor)
    }

    private static func rotate(_ m: [[Bool]]) -> [[Bool]] {
        (0..<3).map { y in (0..<3).map { x in m[2 - x][y] } }
    }

    /// Rellena con muro los callejones sin salida (suelo con 3 o 4 vecinos muro), repetidamente.
    private static func fillDeadEnds(_ room: inout Room) {
        var changed = true
        while changed {
            changed = false
            for y in 0..<room.height {
                for x in 0..<room.width where room.isFloor(x, y) {
                    let open = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)].count(where: { room.isFloor($0.0, $0.1) })
                    if open <= 1 {
                        room.floor[y * room.width + x] = false
                        changed = true
                    }
                }
            }
        }
    }

    /// Deja solo la región de suelo conectada más grande.
    private static func keepLargestRegion(_ room: inout Room) {
        var region = [Int](repeating: -1, count: room.floor.count)
        var sizes: [Int] = []
        for start in room.floor.indices where room.floor[start] && region[start] < 0 {
            let id = sizes.count
            var stack = [start]
            region[start] = id
            var size = 0
            while let c = stack.popLast() {
                size += 1
                let x = c % room.width, y = c / room.width
                for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] where room.isFloor(nx, ny) {
                    let n = ny * room.width + nx
                    if region[n] < 0 {
                        region[n] = id
                        stack.append(n)
                    }
                }
            }
            sizes.append(size)
        }
        guard let largest = sizes.indices.max(by: { sizes[$0] < sizes[$1] }) else { return }
        for i in room.floor.indices where region[i] != largest {
            room.floor[i] = false
        }
    }

    /// `true` si hay una zona abierta de 3×4 o 4×3 casillas de suelo (niveles demasiado vacíos).
    private static func hasOpenArea(_ room: Room) -> Bool {
        for (w, h) in [(3, 4), (4, 3)] {
            for y in 0...max(0, room.height - h) {
                for x in 0...max(0, room.width - w) {
                    var open = true
                    outer: for dy in 0..<h {
                        for dx in 0..<w where !room.isFloor(x + dx, y + dy) {
                            open = false
                            break outer
                        }
                    }
                    if open { return true }
                }
            }
        }
        return false
    }
}
