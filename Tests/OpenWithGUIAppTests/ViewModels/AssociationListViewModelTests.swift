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
    func filtersVisibleRowsBySelectedStatus() async throws {
        let preview = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: nil, candidateApps: []),
                ExtensionAssociationRow(rawExtension: "md", currentDefaultApp: nil, candidateApps: [])
            ],
            apps: [preview]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()
        viewModel.applyStatusFilter(.noDefaultApp)

        #expect(viewModel.visibleRows.map(\.normalizedExtension) == ["json", "md"])
    }

    @Test
    func filtersVisibleRowsByNoIssuesStatus() async throws {
        let preview = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: preview, candidateApps: [preview, preview]),
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: nil, candidateApps: []),
                ExtensionAssociationRow(rawExtension: "md", currentDefaultApp: nil, candidateApps: [])
            ],
            apps: [preview]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()
        viewModel.applyStatusFilter(.noIssues)

        #expect(viewModel.visibleRows.map(\.normalizedExtension) == ["png"])
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
    func clearStatusFilterSelectingFirstVisibleRowResetsSelectionToTopRow() async throws {
        let preview = AppDescriptor(
            bundleIdentifier: "com.apple.Preview",
            displayName: "Preview",
            appURL: URL(fileURLWithPath: "/Applications/Preview.app"),
            isAvailable: true
        )

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "png", currentDefaultApp: preview, candidateApps: [preview]),
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: nil, candidateApps: []),
                ExtensionAssociationRow(rawExtension: "md", currentDefaultApp: nil, candidateApps: [])
            ],
            apps: [preview]
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()
        viewModel.applyStatusFilter(.noDefaultApp)
        viewModel.selection = ["md"]

        viewModel.clearStatusFilterSelectingFirstVisibleRow()

        #expect(viewModel.selectedStatusFilter == nil)
        #expect(viewModel.selection == ["json"])
    }

    @Test
    func clearFilterSelectingFirstVisibleRowResetsSelectionToTopRow() async throws {
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
        viewModel.selection = ["png"]

        viewModel.clearDefaultAppFilterSelectingFirstVisibleRow()

        #expect(viewModel.selectedDefaultAppBundleIdentifier == nil)
        #expect(viewModel.selection == ["json"])
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
    func filtersRowsByExtensionOnly() async throws {
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

        #expect(viewModel.visibleRows.isEmpty)

        viewModel.searchText = "json"

        #expect(viewModel.visibleRows.map(\.normalizedExtension) == ["json"])
    }

    @Test
    func doesNotShowFullEmptyStateWhenSearchHasNoMatchesButRowsExist() async throws {
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
        viewModel.searchText = "does-not-exist"

        #expect(viewModel.visibleRows.isEmpty)
        #expect(viewModel.shouldShowFullEmptyState == false)
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

    @Test
    func removeUserAddedExtensionReloadsRowsAndSelectsFirstVisibleRow() async throws {
        let textEdit = AppDescriptor(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            appURL: URL(fileURLWithPath: "/Applications/TextEdit.app"),
            isAvailable: true
        )

        let removed = LockedFlag(false)

        let repository = RepositoryStub(
            rows: [
                ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: textEdit, candidateApps: [textEdit]),
                ExtensionAssociationRow(rawExtension: "md", currentDefaultApp: nil, candidateApps: [], isUserAdded: true)
            ],
            apps: [textEdit],
            loadRowsHandler: {
                removed.value
                    ? [ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: textEdit, candidateApps: [textEdit])]
                    : [
                        ExtensionAssociationRow(rawExtension: "json", currentDefaultApp: textEdit, candidateApps: [textEdit]),
                        ExtensionAssociationRow(rawExtension: "md", currentDefaultApp: nil, candidateApps: [], isUserAdded: true)
                    ]
            },
            removeUserExtensionHandler: { _ in
                removed.set(true)
            }
        )

        let viewModel = AssociationListViewModel(repository: repository, writer: WriterStub(results: []))
        await viewModel.load()
        viewModel.selection = ["md"]

        await viewModel.removeUserExtension("md")

        #expect(viewModel.rows.map(\.normalizedExtension) == ["json"])
        #expect(viewModel.selection == ["json"])
    }
}

private struct RepositoryStub: AssociationRepository, Sendable {
    var rows: [ExtensionAssociationRow]
    var apps: [AppDescriptor]
    var refreshedRows: [ExtensionAssociationRow]? = nil
    var loadRowsHandler: (@Sendable () async throws -> [ExtensionAssociationRow])? = nil
    var removeUserExtensionHandler: (@Sendable (String) async throws -> Void)? = nil

    func loadRows() async throws -> [ExtensionAssociationRow] {
        if let loadRowsHandler {
            return try await loadRowsHandler()
        }

        return rows
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

    func removeUserExtension(_ normalizedExtension: String) async throws {
        if let removeUserExtensionHandler {
            try await removeUserExtensionHandler(normalizedExtension)
        }
    }
}

private final class LockedFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Bool

    init(_ value: Bool) {
        storage = value
    }

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func set(_ newValue: Bool) {
        lock.lock()
        storage = newValue
        lock.unlock()
    }
}

private struct WriterStub: AssociationWriter, Sendable {
    var results: [AssociationWriteResult]

    func setDefaultApp(_ app: AppDescriptor, for normalizedExtensions: [String]) async throws -> [AssociationWriteResult] {
        results
    }
}
