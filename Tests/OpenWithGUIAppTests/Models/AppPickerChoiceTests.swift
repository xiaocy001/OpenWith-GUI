import Foundation
import Testing
@testable import OpenWithGUIApp

struct AppPickerChoiceTests {
    @Test
    func appChoiceUsesAppIdentityForDisplay() {
        let app = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let choice = AppPickerChoice.app(app)

        #expect(choice.id == "app:com.apple.TextEdit")
        #expect(choice.title == "TextEdit")
        #expect(choice.subtitle == "com.apple.TextEdit")
    }

    @Test
    func specialChoiceCanRepresentAllAppsWithoutAnAppDescriptor() {
        let choice = AppPickerChoice.special(
            id: "all-apps",
            title: "All Apps",
            subtitle: "Show every current default app binding"
        )

        #expect(choice.id == "special:all-apps")
        #expect(choice.title == "All Apps")
        #expect(choice.subtitle == "Show every current default app binding")
        #expect(choice.appDescriptor == nil)
    }
}
