import Foundation
import Testing
@testable import OpenWithGUIApp

struct SystemAssociationRepositoryTests {
    @Test
    func mergesScannedAndUserAddedExtensionsAndResolvesDefaults() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let repository = SystemAssociationRepository(
            scanner: .init(
                scanHandler: {
                    InstalledAppCatalog(
                        allApps: [textEdit],
                        candidateAppsByExtension: ["json": [textEdit]]
                    )
                }
            ),
            launchServices: .init(
                defaultAppURLHandler: { identifier in
                    identifier == "public.json" ? textEdit.appURL : nil
                },
                setDefaultHandler: { _, _ in },
                allHandlersHandler: { _ in [] }
            ),
            userStore: .init(
                loadHandler: { Set(["md"]) },
                addHandler: { _ in }
            )
        )

        let rows = try await repository.loadRows()

        #expect(rows.map(\.normalizedExtension) == ["json", "md"])
        #expect(rows.first?.currentDefaultApp?.bundleIdentifier == "com.apple.TextEdit")
        #expect(rows.last?.statusFlags.contains(.userAddedRule) == true)
    }
}
