import Foundation
import Testing
@testable import OpenWithGUIApp

struct AppPickerSectionTests {
    @Test
    func groupsCandidateAppsAheadOfOtherAppsWithoutDuplication() {
        let candidate = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )
        let other = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let sections = AppPickerSection.makeSections(
            apps: [candidate, other],
            candidateApps: [candidate],
            searchText: ""
        )

        #expect(sections.map(\.title) == ["Candidate Apps", "Other Apps"])
        #expect(sections[0].apps == [candidate])
        #expect(sections[1].apps == [other])
    }

    @Test
    func omitsEmptyCandidateSection() {
        let app = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let sections = AppPickerSection.makeSections(
            apps: [app],
            candidateApps: [],
            searchText: ""
        )

        #expect(sections.map(\.title) == ["Other Apps"])
        #expect(sections[0].apps == [app])
    }
}
