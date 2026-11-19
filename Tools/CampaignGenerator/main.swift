// © 2026 App-Zilla. Licencia MIT.
// Genera Sources/ElkununCore/CampaignLevels.swift con los 60 niveles de la campaña.
// Uso: Scripts/generate-campaign.sh

import Foundation

setvbuf(stdout, nil, _IONBF, 0)
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Sources/ElkununCore/CampaignLevels.swift"

final class Results: @unchecked Sendable {
    private let lock = NSLock()
    private var levels = [GeneratedLevel?](repeating: nil, count: Campaign.levelCount)
    subscript(i: Int) -> GeneratedLevel? {
        get { lock.withLock { levels[i] } }
        set { lock.withLock { levels[i] = newValue } }
    }
}

let results = Results()
let start = Date()
DispatchQueue.concurrentPerform(iterations: Campaign.levelCount) { i in
    do {
        let g = try LevelGenerator.generate(seed: Campaign.seed(for: i), settings: Campaign.settings(for: i))
        results[i] = g
        print("nivel \(i + 1): \(g.solution.pushCount) empujes, puntuación \(g.score)")
    } catch {
        print("nivel \(i + 1): ERROR \(error)")
    }
}

let generated = (0..<Campaign.levelCount).compactMap { results[$0] }
guard generated.count == Campaign.levelCount else {
    print("Faltan niveles; no se escribe el archivo.")
    exit(1)
}
// Orden global de menor a mayor dificultad, para que la curva sea siempre creciente.
let ordered = generated.sorted {
    ($0.score, $0.solution.pushCount, $0.seed) < ($1.score, $1.solution.pushCount, $1.seed)
}

var swift = """
// Archivo generado por Scripts/generate-campaign.sh — no editar a mano.
// © 2026 App-Zilla. Licencia MIT.

enum CampaignLevels {
    static let entries: [Campaign.Entry] = [

"""
for (n, g) in ordered.enumerated() {
    let body = g.level.xsb.split(separator: "\n").map { "            " + $0 }.joined(separator: "\n")
    swift += """
            // \(n + 1) · grupo \(n / Campaign.levelsPerGroup + 1) · \(g.level.boxes.count) cajas · puntuación \(g.score)
            Campaign.Entry(
                seed: 0x\(String(g.seed, radix: 16, uppercase: true)),
                optimalPushes: \(g.solution.pushCount),
                solutionMoves: \(g.solution.moveCount),
                solution: "\(g.solution.lurd)",
                xsb: #\"\"\"
    \(body)
                \"\"\"#),

    """
}
swift += "    ]\n}\n"
try! swift.write(toFile: output, atomically: true, encoding: .utf8)
print("Escrito \(output) en \(Int(Date().timeIntervalSince(start))) s")
