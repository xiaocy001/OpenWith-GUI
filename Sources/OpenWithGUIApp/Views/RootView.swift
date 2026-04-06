import SwiftUI
import Observation

struct RootView: View {
    @State private var showingBatchPicker = false
    @State private var showingAddSheet = false
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
                content
            }
        }
        .task {
            if viewModel.phase == .idle {
                await viewModel.load()
            }
        }
    }

    private var content: some View {
        @Bindable var bindableViewModel = viewModel

        return HSplitView {
            AssociationTableView(viewModel: bindableViewModel)
                .frame(minWidth: 760)

            sidebar
                .frame(minWidth: 320, idealWidth: 360)
        }
        .searchable(text: $bindableViewModel.searchText, placement: .toolbar)
        .toolbar {
            ToolbarItemGroup {
                Button("Refresh") {
                    Task { await viewModel.load() }
                }

                Button("Set Selected to App") {
                    showingBatchPicker = true
                }
                .disabled(viewModel.selection.isEmpty)

                Button("Add Extension") {
                    showingAddSheet = true
                }
            }
        }
        .sheet(isPresented: $showingBatchPicker) {
            AppPickerSheet(
                apps: viewModel.availableApps,
                title: "Set Selected Extensions",
                onSelect: { app in
                    Task {
                        await viewModel.apply(app: app, to: Array(viewModel.selection).sorted())
                    }
                    showingBatchPicker = false
                }
            )
        }
        .sheet(isPresented: $showingSinglePicker) {
            AppPickerSheet(
                apps: viewModel.availableApps,
                title: "Set Default App for .\(singleSelectionExtension ?? "")",
                onSelect: { app in
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
                }
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
}

private struct PreviewAssociationWriter: AssociationWriter {
    func setDefaultApp(_ app: AppDescriptor, for normalizedExtensions: [String]) async throws -> [AssociationWriteResult] {
        []
    }
}
