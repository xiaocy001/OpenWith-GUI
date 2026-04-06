import SwiftUI
import Observation

struct AssociationTableView: View {
    @Bindable var viewModel: AssociationListViewModel

    var body: some View {
        Table(viewModel.visibleRows, selection: $viewModel.selection) {
            TableColumn("Extension") { row in
                Text(row.displayExtension)
                    .font(.system(.body, design: .monospaced))
            }

            TableColumn("Default App") { row in
                Text(row.currentDefaultApp?.displayName ?? "Not Set")
                    .foregroundStyle(row.currentDefaultApp == nil ? .secondary : .primary)
            }

            TableColumn("Candidate Apps") { row in
                Text("\(row.candidateApps.count)")
            }

            TableColumn("Status") { row in
                Text(row.statusFlags.map(\.rawValue).joined(separator: ", "))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
