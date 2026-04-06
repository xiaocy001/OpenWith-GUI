import AppKit
import SwiftUI

struct AppPickerSheet: View {
    let apps: [AppDescriptor]
    let title: String
    let onSelect: (AppDescriptor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())

            TextField("Search apps", text: $searchText)

            List(filteredApps) { app in
                Button {
                    onSelect(app)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                            .resizable()
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.displayName)
                            Text(app.bundleIdentifier)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: 320)
        }
        .padding()
        .frame(width: 520, height: 480)
    }

    private var filteredApps: [AppDescriptor] {
        guard !searchText.isEmpty else {
            return apps
        }

        let query = searchText.lowercased()
        return apps.filter {
            $0.displayName.lowercased().contains(query)
                || $0.bundleIdentifier.lowercased().contains(query)
        }
    }
}
