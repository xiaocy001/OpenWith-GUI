import Foundation
import Testing
@testable import OpenWithGUIApp

struct ExtensionAssociationRowTests {
    @Test
    func normalizeStripsDotsWhitespaceAndLowercases() {
        #expect(ExtensionAssociationRow.normalize(" .JSON ") == "json")
        #expect(ExtensionAssociationRow.normalize("md") == "md")
        #expect(ExtensionAssociationRow.normalize("...") == nil)
    }

    @Test
    func derivesStatusFlagsFromAvailabilityCandidatesAndWriteResult() {
        let missingApp = AppDescriptor(
            bundleIdentifier: "com.example.missing",
            displayName: "Missing App",
            appURL: URL(fileURLWithPath: "/Missing.app"),
            isAvailable: false
        )

        let row = ExtensionAssociationRow(
            rawExtension: ".json",
            currentDefaultApp: missingApp,
            candidateApps: [missingApp],
            isUserAdded: true,
            lastOperationResult: .failed(message: "write failed")
        )

        #expect(row.displayExtension == ".json")
        #expect(Set(row.statusFlags) == Set([
            .missingDefaultApp,
            .singleCandidate,
            .userAddedRule,
            .writeFailed
        ]))
    }
}
