import SwiftUI
import Observation

struct RootView: View {
    @State private var hasAppliedInitialSelection = false
    @State private var tableResetToken = 0
    @State private var showingBatchPicker = false
    @State private var showingAddSheet = false
    @State private var showingDefaultAppFilterPicker = false
    @State private var showingStatusFilterPicker = false
    @State private var showingSinglePicker = false
    @State private var singleSelectionExtension: String?
    @State private var viewModel: AssociationListViewModel

    init(viewModel: AssociationListViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? AssociationListViewModel(
            repository: PreviewAssociationRepository(),
            writer: PreviewAssociationWriter()
        ))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle, .loading:
                ProgressView("Loading extension associations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .failed(message):
                ContentUnavailableView(
                    "Unable to Load Associations",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case .loaded:
                if viewModel.shouldShowFullEmptyState {
                    ContentUnavailableView(
                        "No Extensions Available",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("No extensions are currently available.")
                    )
                } else {
                    content
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            if viewModel.phase == .idle {
                await viewModel.load()
            }
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            guard newPhase == .loaded, !hasAppliedInitialSelection else {
                return
            }

            viewModel.selectFirstRowIfNeeded()
            hasAppliedInitialSelection = true
        }
    }

    private var content: some View {
        @Bindable var bindableViewModel = viewModel

        return GeometryReader { proxy in
            HSplitView {
                AssociationTableView(viewModel: bindableViewModel)
                    .background(TableScrollResetView(token: tableResetToken))
                    .frame(minWidth: 760, maxWidth: .infinity, maxHeight: .infinity)

                sidebar
                    .frame(minWidth: 320, idealWidth: 360, maxHeight: .infinity)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.reconcileSelectionForVisibleRows()
        }
        .toolbar {
            ToolbarItemGroup {
                ToolbarSearchField(
                    text: $bindableViewModel.searchText,
                    placeholder: "Search extensions"
                )
                .frame(width: 220)

                Button(viewModel.selectedDefaultAppBundleIdentifier == nil ? "Filter by App" : "Clear App Filter") {
                    if viewModel.selectedDefaultAppBundleIdentifier == nil {
                        showingDefaultAppFilterPicker = true
                    } else {
                        viewModel.clearDefaultAppFilterSelectingFirstVisibleRow()
                        tableResetToken += 1
                    }
                }

                Button(viewModel.selectedStatusFilter == nil ? "Filter by Status" : "Clear Status Filter") {
                    if viewModel.selectedStatusFilter == nil {
                        showingStatusFilterPicker = true
                    } else {
                        viewModel.clearStatusFilterSelectingFirstVisibleRow()
                        tableResetToken += 1
                    }
                }

                Button("Refresh") {
                    Task { await viewModel.load() }
                }

                Button("Add Extension") {
                    showingAddSheet = true
                }
            }
        }
        .sheet(isPresented: $showingDefaultAppFilterPicker) {
            AppPickerSheet(
                apps: viewModel.defaultAppFilterOptions,
                title: "Filter by Default App",
                searchPlaceholder: "Search apps",
                candidateApps: [],
                showsCandidateGrouping: false,
                leadingChoices: [
                    AppPickerChoice.special(
                        id: "all-apps",
                        title: "All Apps",
                        subtitle: "Show every current default app binding"
                    )
                ],
                onSelectChoice: { choice in
                    if choice.id == "special:all-apps" {
                        viewModel.clearDefaultAppFilter()
                    } else if let app = choice.appDescriptor {
                        viewModel.applyDefaultAppFilter(app)
                    }
                    showingDefaultAppFilterPicker = false
                }
            )
        }
        .sheet(isPresented: $showingStatusFilterPicker) {
            AppPickerSheet(
                apps: [],
                title: "Filter by Status",
                searchPlaceholder: "Search statuses",
                candidateApps: [],
                showsCandidateGrouping: false,
                leadingChoices: viewModel.statusFilterOptions.map { status in
                    AppPickerChoice.special(
                        id: "status:\(status.rawValue)",
                        title: status.displayTitle,
                        subtitle: status.displaySubtitle
                    )
                },
                onSelectChoice: { choice in
                    guard let statusRawValue = choice.id.split(separator: ":").last,
                          let status = AssociationStatusFlag(rawValue: String(statusRawValue)) else {
                        showingStatusFilterPicker = false
                        return
                    }

                    viewModel.applyStatusFilter(status)
                    showingStatusFilterPicker = false
                }
            )
        }
        .sheet(isPresented: $showingBatchPicker) {
            AppPickerSheet(
                apps: viewModel.availableApps,
                title: "Set Selected Extensions",
                searchPlaceholder: "Search apps",
                candidateApps: [],
                showsCandidateGrouping: false,
                leadingChoices: [],
                onSelectChoice: { choice in
                    guard let app = choice.appDescriptor else {
                        return
                    }

                    Task {
                        await viewModel.apply(app: app, to: Array(viewModel.selection).sorted())
                    }
                    showingBatchPicker = false
                }
            )
        }
        .sheet(isPresented: $showingSinglePicker, onDismiss: {
            singleSelectionExtension = nil
        }) {
            let selectedRow = viewModel.rows.first { $0.normalizedExtension == singleSelectionExtension }

            AppPickerSheet(
                apps: viewModel.availableApps,
                title: "Set Default App for .\(singleSelectionExtension ?? "")",
                searchPlaceholder: "Search apps",
                candidateApps: selectedRow?.candidateApps ?? [],
                showsCandidateGrouping: true,
                leadingChoices: [],
                onSelectChoice: { choice in
                    guard let app = choice.appDescriptor else {
                        return
                    }

                    guard let normalizedExtension = singleSelectionExtension else {
                        return
                    }

                    Task {
                        await viewModel.apply(app: app, to: [normalizedExtension])
                    }
                    singleSelectionExtension = nil
                    showingSinglePicker = false
                }
            )
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExtensionSheet(
                apps: viewModel.availableApps,
                onSubmit: { rawExtension, app in
                    Task {
                        await viewModel.addExtension(rawExtension, app: app)
                    }
                    showingAddSheet = false
                }
            )
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if viewModel.selection.count > 1 {
            BatchActionSidebar(
                selectionCount: viewModel.selection.count,
                lastBatchSummary: viewModel.lastBatchSummary,
                onChooseApp: { showingBatchPicker = true }
            )
        } else if let row = viewModel.primarySelectedRow {
            AssociationDetailSidebar(
                row: row,
                onChooseApp: {
                    singleSelectionExtension = row.normalizedExtension
                    showingSinglePicker = true
                },
                onRemoveExtension: row.isUserAdded ? {
                    Task {
                        await viewModel.removeUserExtension(row.normalizedExtension)
                    }
                } : nil
            )
        } else {
            ContentUnavailableView(
                "Select an Extension",
                systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                description: Text("Choose one row to inspect its default app and candidates.")
            )
        }
    }
}

private struct PreviewAssociationRepository: AssociationRepository {
    func loadRows() async throws -> [ExtensionAssociationRow] {
        []
    }

    func refreshRows(for normalizedExtensions: [String]) async throws -> [ExtensionAssociationRow] {
        []
    }

    func loadAppChoices() async throws -> [AppDescriptor] {
        []
    }

    func addUserExtension(_ rawExtension: String) async throws -> String {
        ExtensionAssociationRow.normalize(rawExtension) ?? rawExtension
    }

    func removeUserExtension(_ normalizedExtension: String) async throws {
    }
}

private struct PreviewAssociationWriter: AssociationWriter {
    func setDefaultApp(_ app: AppDescriptor, for normalizedExtensions: [String]) async throws -> [AssociationWriteResult] {
        []
    }
}
