// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkunufeCore

@Suite("ElkunufeCore")
struct ElkunufeCoreTests {
    @Test("El núcleo expone su versión")
    func version() {
        #expect(!ElkunufeCore.version.isEmpty)
    }
}
