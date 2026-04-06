import CoreServices
import Foundation

struct LaunchServicesClient: Sendable {
    var defaultAppURLHandler: @Sendable (String) throws -> URL?
    var setDefaultHandlerHandler: @Sendable (String, String) throws -> Void
    var allHandlersHandler: @Sendable (String) -> [String]

    init(
        defaultAppURLHandler: @escaping @Sendable (String) throws -> URL?,
        setDefaultHandler: @escaping @Sendable (String, String) throws -> Void,
        allHandlersHandler: @escaping @Sendable (String) -> [String]
    ) {
        self.defaultAppURLHandler = defaultAppURLHandler
        self.setDefaultHandlerHandler = setDefaultHandler
        self.allHandlersHandler = allHandlersHandler
    }

    static let live = LaunchServicesClient(
        defaultAppURLHandler: { identifier in
            var error: Unmanaged<CFError>?
            let result = LSCopyDefaultApplicationURLForContentType(identifier as CFString, .all, &error)
            if let error {
                throw error.takeRetainedValue() as Error
            }
            return result?.takeRetainedValue() as URL?
        },
        setDefaultHandler: { bundleIdentifier, identifier in
            let status = LSSetDefaultRoleHandlerForContentType(identifier as CFString, .all, bundleIdentifier as CFString)
            guard status == noErr else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
            }
        },
        allHandlersHandler: { identifier in
            guard let unmanaged = LSCopyAllRoleHandlersForContentType(identifier as CFString, .all) else {
                return []
            }
            return unmanaged.takeRetainedValue() as? [String] ?? []
        }
    )

    func defaultAppURL(for identifier: String) throws -> URL? {
        try defaultAppURLHandler(identifier)
    }

    func setDefaultHandler(bundleIdentifier: String, for identifier: String) throws {
        try setDefaultHandlerHandler(bundleIdentifier, identifier)
    }

    func allHandlerBundleIdentifiers(for identifier: String) -> [String] {
        allHandlersHandler(identifier)
    }
}
