import Foundation
import Testing
@testable import OpenWithGUIApp

struct SystemAssociationWriterTests {
    @Test
    func failsUnknownExtensionsAndWritesRecognizedOnes() async throws {
        let writer = SystemAssociationWriter(
            launchServices: .init(
                defaultAppURLHandler: { _ in nil },
                setDefaultHandler: { _, _ in },
                allHandlersHandler: { _ in [] }
            ),
            typeIdentifierResolver: { normalizedExtension in
                normalizedExtension == "json" ? "public.json" : nil
            }
        )

        let app = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let results = try await writer.setDefaultApp(app, for: ["json", "foo"])

        #expect(results.count == 2)
        #expect(results.first?.normalizedExtension == "json")
        #expect(results.first?.errorMessage == nil)
        #expect(results.last?.normalizedExtension == "foo")
        #expect(results.last?.errorMessage == "macOS does not recognize this extension yet.")
    }
}
