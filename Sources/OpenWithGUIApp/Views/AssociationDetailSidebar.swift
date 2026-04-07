import AppKit
import SwiftUI

struct AssociationDetailSidebar: View {
    let row: ExtensionAssociationRow
    let onChooseApp: () -> Void
    let onRemoveExtension: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(row.displayExtension)
                    .font(.largeTitle.bold())

                HStack(spacing: 12) {
                    Button("Change Default App") {
                        onChooseApp()
                    }

                    if let onRemoveExtension {
                        Button("Remove Extension", role: .destructive) {
                            onRemoveExtension()
                        }
                    }
                }

                DetailSection(title: "Current Default App") {
                    if let app = row.currentDefaultApp {
                        AppSummaryView(app: app)
                    } else {
                        Text("No default app is currently set for this extension.")
                            .foregroundStyle(.secondary)
                    }
                }

                DetailSection(title: "Candidate Apps") {
                    if row.candidateApps.isEmpty {
                        Text("No candidate apps were discovered for this extension.")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(row.candidateApps) { app in
                                AppSummaryView(app: app)
                            }
                        }
                    }
                }

                if case let .failed(message) = row.lastOperationResult {
                    Text(message)
                        .foregroundStyle(.red)
                } else if case let .pendingVerification(message) = row.lastOperationResult {
                    Text(message)
                        .foregroundStyle(.orange)
                } else if case let .succeeded(message) = row.lastOperationResult {
                    Text(message)
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(nsColor: .separatorColor))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AppSummaryView: View {
    let app: AppDescriptor

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                .resizable()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                    .font(.headline)
                Text(app.bundleIdentifier)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(app.appURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }
}
