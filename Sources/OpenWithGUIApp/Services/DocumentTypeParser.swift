import Foundation
import UniformTypeIdentifiers

struct DocumentTypeParser {
    var preferredExtensionForTypeIdentifier: (String) -> String?

    init(preferredExtensionForTypeIdentifier: @escaping (String) -> String? = { identifier in
        UTType(identifier)?.preferredFilenameExtension
    }) {
        self.preferredExtensionForTypeIdentifier = preferredExtensionForTypeIdentifier
    }

    func extensions(from infoPlist: [String: Any]) -> Set<String> {
        guard let documentTypes = infoPlist["CFBundleDocumentTypes"] as? [[String: Any]] else {
            return []
        }

        var result: Set<String> = []

        for documentType in documentTypes {
            let directExtensions = (documentType["CFBundleTypeExtensions"] as? [String] ?? [])
                .compactMap(ExtensionAssociationRow.normalize)
                .filter { $0 != "*" }

            result.formUnion(directExtensions)

            let contentTypes = documentType["LSItemContentTypes"] as? [String] ?? []
            for identifier in contentTypes {
                if let derived = preferredExtensionForTypeIdentifier(identifier),
                   let normalized = ExtensionAssociationRow.normalize(derived) {
                    result.insert(normalized)
                }
            }
        }

        return result
    }
}
