import Foundation
import Testing
@testable import OpenWithGUIApp

@MainActor
struct AssociationListViewModelTests {
    @Test
    func exposesUniqueSortedDefaultAppFilterOptions() async throws {
        let preview = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )
        let xcode = AppDescriptor(
            bundleIdentifier: "com.apple.dt.Xcode",
            displayName: "Xcode",
            appURL: URL(fileURLWithPath: "/Applications/Xcode.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "jpg", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "swift", currentDefaultApp: xcode, candidateApps: [xcode])
            ],
            apps: [preview, xcode]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()

        #expect(viewModel.defaultAppFilterOptions.map(\.bundleIdentifier) == [
            "com.apple.Preview",
            "com.apple.dt.Xcode"
        ])
    }

    @Test
    func filtersVisibleRowsBySelectedDefaultApp() async throws {
        let preview = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )
        let xcode = AppDescriptor(
            bundleIdentifier: "com.apple.dt.Xcode",
            displayName: "Xcode",
            appURL: URL(fileURLWithPath: "/Applications/Xcode.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "jpg", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "swift", currentDefaultApp: xcode, candidateApps: [xcode])
            ],
            apps: [preview, xcode]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()
        viewModel.applyDefaultAppFilter(preview)

        #expect(viewModel.visibleRows.map(\.normalizedExtension) == ["jpg", "png"])
    }

    @Test
    func clearsFilterBackToAllApps() async throws {
        let preview = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: nil, candidateApps: [])
            ],
            apps: [preview]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()
        viewModel.applyDefaultAppFilter(preview)
        viewModel.clearDefaultAppFilter()

        #expect(viewModel.visibleRows.map(\.normalizedExtension) == ["json", "png"])
    }

    @Test
    func movesSelectionToFirstVisibleRowWhenFilterHidesCurrentSelection() async throws {
        let preview = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )
        let xcode = AppDescriptor(
            bundleIdentifier: "com.apple.dt.Xcode",
            displayName: "Xcode",
            appURL: URL(fileURLWithPath: "/Applications/Xcode.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "jpg", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "swift", currentDefaultApp: xcode, candidateApps: [xcode])
            ],
            apps: [preview, xcode]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()
        viewModel.selection = ["swift"]
        viewModel.applyDefaultAppFilter(preview)

        #expect(viewModel.selection == ["jpg"])
    }

    @Test
    func selectsFirstRowAfterInitialLoadWhenSelectionIsEmpty() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: textEdit, candidateApps: [textEdit]),
                ExtensionAssociationRow(rawExtension: "md", currentDefaultApp: nil, candidateApps: [])
            ],
            apps: [textEdit]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))

        await viewModel.load()
        viewModel.selectFirstRowIfNeeded()

        #expect(viewModel.selection == ["json"])
    }

    @Test
    func filtersRowsByExtensionAndAppName() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: textEdit, candidateApps: [textEdit]),
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: nil, candidateApps: [])
            ],
            apps: [textEdit]
        )

        let viewModel = AssociationListViewModel(
            repository: repository,
            writer: WriterStub(results: [])
        )

        await viewModel.load()
        viewModel.searchText = "textedit"

        #expect(viewModel.visibleRows.map(\.normalizedExtension) == ["json"])
    }

    @Test
    func batchApplyMarksRefreshMismatchAsPendingVerification() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: nil, candidateApps: [textEdit])],
            apps: [textEdit],
            refreshedRows: [ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: nil, candidateApps: [textEdit])]
        )

        let writer = WriterStub(results: [
            AssociationWriteResult(normalizedExtension: "json", errorMessage: nil)
        ])

        let viewModel = AssociationListViewModel(repository: repository, writer: writer)
        await viewModel.load()
        viewModel.selection = ["json"]

        await viewModel.apply(app: textEdit, to: ["json"])

        #expect(viewModel.rows.first?.statusFlags.contains(.writePendingVerification) == true)
    }

    @Test
    func addExtensionNormalizesInputBeforeWriting() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [],
            apps: [textEdit],
            refreshedRows: [
                ExtensionAssociationRow(
                    rawExtension: "json",
                    currentDefaultApp: textEdit,
                    candidateApps: [textEdit],
                    isUserAdded: true
                )
            ]
        )

        let writer = WriterStub(results: [
            AssociationWriteResult(normalizedExtension: "json", errorMessage: nil)
        ])

        let viewModel = AssociationListViewModel(repository: repository, writer: writer)
        await viewModel.load()
        await viewModel.addExtension(".JSON", app: textEdit)

        #expect(viewModel.rows.first?.normalizedExtension == "json")
        #expect(viewModel.rows.first?.statusFlags.contains(.userAddedRule) == true)
    }
}

private struct RepositoryStub: AssociationRepository, Sendable {
    var rows: [ExtensionAssociationRow]
    var apps: [AppDescriptor]
    var refreshedRows: [ExtensionAssociationRow]? = nil

    func loadRows() async throws -> [ExtensionAssociationRow] {
        rows
    }

    func refreshRows(for normalizedExtensions: [String]) async throws -> [ExtensionAssociationRow] {
        refreshedRows ?? rows
    }

    func loadAppChoices() async throws -> [AppDescriptor] {
        apps
    }

    func addUserExtension(_ rawExtension: String) async throws -> String {
        ExtensionAssociationRow.normalize(rawExtension) ?? rawExtension
    }
}

private struct WriterStub: AssociationWriter, Sendable {
    var results: [AssociationWriteResult]

    func setDefaultApp(_ app: AppDescriptor, for normalizedExtensions: [String]) async throws -> [AssociationWriteResult] {
        results
    }
}
