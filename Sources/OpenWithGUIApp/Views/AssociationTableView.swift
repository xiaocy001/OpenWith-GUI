import AppKit
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
                if let app = row.currentDefaultApp {
                    HStack(spacing: 8) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(app.displayName)
                    }
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
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
