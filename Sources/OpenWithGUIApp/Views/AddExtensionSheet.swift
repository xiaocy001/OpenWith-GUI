import SwiftUI

struct AddExtensionSheet: View {
    let apps: [AppDescriptor]
    let onSubmit: (String, AppDescriptor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rawExtension = ""
    @State private var selectedAppID: AppDescriptor.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Extension")
                .font(.title2.bold())

            TextField("json", text: $rawExtension)
                .textFieldStyle(.roundedBorder)

            Picker("Default App", selection: $selectedAppID) {
                Text("Choose an app").tag(AppDescriptor.ID?.none)
                ForEach(apps) { app in
                    Text(app.displayName).tag(AppDescriptor.ID?.some(app.id))
                }
            }

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
    }
}
