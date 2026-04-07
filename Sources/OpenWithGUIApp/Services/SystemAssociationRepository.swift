import Foundation
import UniformTypeIdentifiers

struct SystemAssociationRepository: AssociationRepository {
    struct ScannerAdapter: Sendable {
        var scanHandler: @Sendable () -> InstalledAppCatalog

        static let live = ScannerAdapter {
            AppCatalogScanner().scan()
        }
    }

    struct UserStoreAdapter: Sendable {
        var loadHandler: @Sendable () throws -> Set<String>
        var addHandler: @Sendable (String) throws -> Void
        var removeHandler: @Sendable (String) throws -> Void

        init(
            loadHandler: @escaping @Sendable () throws -> Set<String>,
            addHandler: @escaping @Sendable (String) throws -> Void,
            removeHandler: @escaping @Sendable (String) throws -> Void = { _ in }
        ) {
            self.loadHandler = loadHandler
            self.addHandler = addHandler
            self.removeHandler = removeHandler
        }

        static let live = UserStoreAdapter(
            loadHandler: { try UserAddedExtensionStore().load() },
            addHandler: { try UserAddedExtensionStore().add($0) },
            removeHandler: { try UserAddedExtensionStore().remove($0) }
        )
    }

    let scanner: ScannerAdapter
    let launchServices: LaunchServicesClient
    let userStore: UserStoreAdapter

    init(
        scanner: ScannerAdapter,
        launchServices: LaunchServicesClient,
        userStore: UserStoreAdapter
    ) {
        self.scanner = scanner
        self.launchServices = launchServices
        self.userStore = userStore
    }

    func loadRows() async throws -> [ExtensionAssociationRow] {
        try await rows(filteredTo: nil)
    }

    func refreshRows(for normalizedExtensions: [String]) async throws -> [ExtensionAssociationRow] {
        try await rows(filteredTo: Set(normalizedExtensions))
    }

    func loadAppChoices() async throws -> [AppDescriptor] {
        scanner.scanHandler().allApps
    }

    func addUserExtension(_ rawExtension: String) async throws -> String {
        guard let normalized = ExtensionAssociationRow.normalize(rawExtension) else {
            throw UserAddedExtensionStore.ValidationError.invalidExtension
        }

        try userStore.addHandler(normalized)
        return normalized
    }

    func removeUserExtension(_ normalizedExtension: String) async throws {
        try userStore.removeHandler(normalizedExtension)
    }

    private func rows(filteredTo filter: Set<String>?) async throws -> [ExtensionAssociationRow] {
        let catalog = scanner.scanHandler()
        let userAddedExtensions = try userStore.loadHandler()

        let allExtensions = Set(catalog.candidateAppsByExtension.keys).union(userAddedExtensions)
        let targetExtensions = filter.map { allExtensions.intersection($0) } ?? allExtensions

        return targetExtensions
            .map { normalizedExtension in
                ExtensionAssociationRow(
                    rawExtension: normalizedExtension,
                    currentDefaultApp: resolveDefaultApp(for: normalizedExtension, catalog: catalog),
                    candidateApps: catalog.candidateAppsByExtension[normalizedExtension, default: []],
                    isUserAdded: userAddedExtensions.contains(normalizedExtension)
                )
            }
            .sorted { $0.normalizedExtension < $1.normalizedExtension }
    }

    private func resolveDefaultApp(for normalizedExtension: String, catalog: InstalledAppCatalog) -> AppDescriptor? {
        guard let type = UTType(filenameExtension: normalizedExtension),
              let url = try? launchServices.defaultAppURL(for: type.identifier) else {
            return nil
        }

        if let knownApp = catalog.allApps.first(where: { $0.appURL == url }) {
            return knownApp
        }

        let bundle = Bundle(url: url)
        let bundleIdentifier = bundle?.bundleIdentifier ?? "unknown.\(normalizedExtension)"

        return AppDescriptor(
            bundleIdentifier: bundleIdentifier,
            displayName: FileManager.default.displayName(atPath: url.path),
            appURL: url,
            isAvailable: FileManager.default.fileExists(atPath: url.path)
        )
    }
}
