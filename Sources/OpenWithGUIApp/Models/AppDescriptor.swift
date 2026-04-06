import Foundation

struct AppDescriptor: Identifiable, Hashable, Sendable {
    let bundleIdentifier: String
    let displayName: String
    let appURL: URL
    let isAvailable: Bool

    var id: String { bundleIdentifier }
}
