import Foundation
import UniformTypeIdentifiers

struct SystemAssociationWriter: AssociationWriter {
    let launchServices: LaunchServicesClient
    let typeIdentifierResolver: @Sendable (String) -> String?

    init(
        launchServices: LaunchServicesClient = .live,
        typeIdentifierResolver: @escaping @Sendable (String) -> String? = { normalizedExtension in
            UTType(filenameExtension: normalizedExtension)?.identifier
        }
    ) {
        self.launchServices = launchServices
        self.typeIdentifierResolver = typeIdentifierResolver
    }

    func setDefaultApp(_ app: AppDescriptor, for normalizedExtensions: [String]) async throws -> [AssociationWriteResult] {
        normalizedExtensions.map { normalizedExtension in
            guard let typeIdentifier = typeIdentifierResolver(normalizedExtension) else {
                return AssociationWriteResult(
                    normalizedExtension: normalizedExtension,
                    errorMessage: "macOS does not recognize this extension yet."
                )
            }

            do {
                try launchServices.setDefaultHandler(bundleIdentifier: app.bundleIdentifier, for: typeIdentifier)
                return AssociationWriteResult(normalizedExtension: normalizedExtension, errorMessage: nil)
            } catch {
                return AssociationWriteResult(
                    normalizedExtension: normalizedExtension,
                    errorMessage: "macOS did not accept this default-app change."
                )
            }
        }
    }
}
