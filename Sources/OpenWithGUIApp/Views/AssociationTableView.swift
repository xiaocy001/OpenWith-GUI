import AppKit
import SwiftUI
import Observation

struct AssociationTableView: View {
    @Bindable var viewModel: AssociationListViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(nsColor: .controlBackgroundColor)

            Table(viewModel.visibleRows, selection: $viewModel.selection) {
                TableColumn("Extension") { row in
                    Text(row.displayExtension)
                        .font(.system(.body, design: .monospaced))
                }

                TableColumn("Default App") { row in
                    if let app = row.currentDefaultApp {
                        Button {
                            viewModel.applyDefaultAppFilter(app)
                        } label: {
                            HStack(spacing: 4) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                Text(app.displayName)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }

                TableColumn("Bundle ID") { row in
                    if let bundleIdentifier = row.currentDefaultApp?.bundleIdentifier {
                        Text(bundleIdentifier)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }

                TableColumn("Status") { row in
                    Text(row.statusDisplayText)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
