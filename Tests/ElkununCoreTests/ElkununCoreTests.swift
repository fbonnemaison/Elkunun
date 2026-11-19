// © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import ElkununCore

@Suite("ElkununCore")
struct ElkununCoreTests {
    @Test("El núcleo expone su versión")
    func version() {
        #expect(!ElkununCore.version.isEmpty)
    }
}
