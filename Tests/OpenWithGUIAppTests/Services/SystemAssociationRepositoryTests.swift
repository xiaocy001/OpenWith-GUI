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

    @Test
    func removingUserAddedExtensionDropsStandaloneUserAddedRow() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let removedExtensions = LockedValue<[String]>([])
        let userAddedExtensions = LockedValue<Set<String>>(["md"])

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
                loadHandler: { userAddedExtensions.value },
                addHandler: { _ in },
                removeHandler: { extensionToRemove in
                    removedExtensions.withValue { $0.append(extensionToRemove) }
                    userAddedExtensions.withValue { $0.remove(extensionToRemove) }
                }
            )
        )

        try await repository.removeUserExtension("md")
        let rows = try await repository.loadRows()

        #expect(removedExtensions.value == ["md"])
        #expect(rows.map(\.normalizedExtension) == ["json"])
    }
}

private final class LockedValue<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    @discardableResult
    func withValue<T>(_ body: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&storage)
    }
}
