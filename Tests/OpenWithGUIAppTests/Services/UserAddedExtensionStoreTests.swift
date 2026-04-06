import Foundation
import Testing
@testable import OpenWithGUIApp

struct UserAddedExtensionStoreTests {
    @Test
    func savesNormalizedExtensionsWithoutDuplicates() throws {
        let suiteName = "UserAddedExtensionStoreTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserAddedExtensionStore(
            defaults: defaults,
            defaultsKey: "userAddedExtensions"
        )

        try store.add(".JSON")
        try store.add("json")
        try store.add(" md ")

        #expect(try store.load() == Set(["json", "md"]))
    }
}
