import SwiftUI

struct BatchActionSidebar: View {
    let selectionCount: Int
    let lastBatchSummary: String?
    let onChooseApp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Batch Update")
                .font(.title.bold())

            Text("\(selectionCount) extensions selected")
                .font(.headline)

            Button("Choose Target App") {
                onChooseApp()
            }

            if let lastBatchSummary {
                Text(lastBatchSummary)
                    .font(.body.monospaced())
            }

            Spacer()
        }
        .padding()
    }
}
