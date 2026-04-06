import Foundation

struct InstalledAppCatalog: Sendable {
    let allApps: [AppDescriptor]
    let candidateAppsByExtension: [String: [AppDescriptor]]
}

struct AppCatalogScanner {
    let parser: DocumentTypeParser
    let fileManager: FileManager
    let applicationDirectories: [URL]

    init(
        parser: DocumentTypeParser = DocumentTypeParser(),
        fileManager: FileManager = .default,
        applicationDirectories: [URL]? = nil
    ) {
        self.parser = parser
        self.fileManager = fileManager
        self.applicationDirectories = applicationDirectories ?? [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
    }

    func scan() -> InstalledAppCatalog {
        var allApps: [AppDescriptor] = []
        var candidates: [String: [AppDescriptor]] = [:]

        for appURL in discoverApplicationBundles() {
            guard let bundle = Bundle(url: appURL),
                  let bundleIdentifier = bundle.bundleIdentifier,
                  let infoDictionary = bundle.infoDictionary else {
                continue
            }

            let app = AppDescriptor(
                bundleIdentifier: bundleIdentifier,
                displayName: fileManager.displayName(atPath: appURL.path),
                appURL: appURL,
                isAvailable: fileManager.fileExists(atPath: appURL.path)
            )

            allApps.append(app)

            for normalizedExtension in parser.extensions(from: infoDictionary) {
                candidates[normalizedExtension, default: []].append(app)
            }
        }

        return InstalledAppCatalog(
            allApps: deduplicatedApps(allApps),
            candidateAppsByExtension: candidates.mapValues(deduplicatedApps)
        )
    }

    private func discoverApplicationBundles() -> [URL] {
        var discovered: [URL] = []

        for directory in applicationDirectories {
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator where url.pathExtension == "app" {
                discovered.append(url)
            }
        }

        return discovered
    }

    private func deduplicatedApps(_ apps: [AppDescriptor]) -> [AppDescriptor] {
        Dictionary(grouping: apps, by: \.bundleIdentifier)
            .compactMap { $0.value.first }
            .sorted { lhs, rhs in
                lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
    }
}
