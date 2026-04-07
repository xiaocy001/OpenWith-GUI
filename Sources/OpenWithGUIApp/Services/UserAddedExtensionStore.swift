import Foundation

struct UserAddedExtensionStore {
    let defaults: UserDefaults
    let defaultsKey: String

    init(
        defaults: UserDefaults = .standard,
        defaultsKey: String = "userAddedExtensions"
    ) {
        self.defaults = defaults
        self.defaultsKey = defaultsKey
    }

    func load() throws -> Set<String> {
        let stored = defaults.stringArray(forKey: defaultsKey) ?? []
        return Set(stored.compactMap(ExtensionAssociationRow.normalize))
    }

    func add(_ rawExtension: String) throws {
        guard let normalized = ExtensionAssociationRow.normalize(rawExtension) else {
            throw ValidationError.invalidExtension
        }

        var current = try load()
        current.insert(normalized)
        defaults.set(Array(current).sorted(), forKey: defaultsKey)
    }

    func remove(_ rawExtension: String) throws {
        guard let normalized = ExtensionAssociationRow.normalize(rawExtension) else {
            throw ValidationError.invalidExtension
        }

        var current = try load()
        current.remove(normalized)
        defaults.set(Array(current).sorted(), forKey: defaultsKey)
    }

    enum ValidationError: Error {
        case invalidExtension
    }
}
