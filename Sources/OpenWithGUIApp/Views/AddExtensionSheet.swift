import AppKit
import SwiftUI

struct AddExtensionSheet: View {
    let apps: [AppDescriptor]
    let onSubmit: (String, AppDescriptor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rawExtension = ""
    @State private var selectedAppID: AppDescriptor.ID?
    @State private var showingAppPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Extension")
                .font(.title2.bold())

            TextField("json", text: $rawExtension)
                .textFieldStyle(.roundedBorder)

            Button {
                showingAppPicker = true
            } label: {
                HStack(spacing: 12) {
                    if let selectedApp = apps.first(where: { $0.id == selectedAppID }) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: selectedApp.appURL.path))
                            .resizable()
                            .frame(width: 20, height: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedApp.displayName)
                            Text(selectedApp.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Choose an app")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Add") {
                    guard let selectedApp = apps.first(where: { $0.id == selectedAppID }) else {
                        return
                    }

                    onSubmit(rawExtension, selectedApp)
                    dismiss()
                }
                .disabled(ExtensionAssociationRow.normalize(rawExtension) == nil || selectedAppID == nil)
            }
        }
        .padding()
        .frame(width: 420)
        .sheet(isPresented: $showingAppPicker) {
            AppPickerSheet(
                apps: apps,
                title: "Choose Default App",
                candidateApps: [],
                showsCandidateGrouping: false,
                leadingChoices: [],
                onSelectChoice: { choice in
                    selectedAppID = choice.appDescriptor?.id
                    showingAppPicker = false
                }
            )
        }
    }
}
