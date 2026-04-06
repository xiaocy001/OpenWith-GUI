import Foundation

struct ExtensionAssociationRow: Identifiable, Equatable, Sendable {
    static let manyCandidateThreshold = 5

    let normalizedExtension: String
    let rawExtension: String
    let currentDefaultApp: AppDescriptor?
    let candidateApps: [AppDescriptor]
    let isUserAdded: Bool
    let lastOperationResult: AssociationOperationResult

    var id: String { normalizedExtension }
    var displayExtension: String { ".\(normalizedExtension)" }
    var statusFlags: [AssociationStatusFlag] { Self.makeStatusFlags(for: self) }

    init(
        rawExtension: String,
        currentDefaultApp: AppDescriptor?,
        candidateApps: [AppDescriptor],
        isUserAdded: Bool = false,
        lastOperationResult: AssociationOperationResult = .idle
    ) {
        guard let normalizedExtension = Self.normalize(rawExtension) else {
            preconditionFailure("ExtensionAssociationRow requires a non-empty normalized extension")
        }

        self.normalizedExtension = normalizedExtension
        self.rawExtension = rawExtension
        self.currentDefaultApp = currentDefaultApp
        self.candidateApps = candidateApps.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        self.isUserAdded = isUserAdded
        self.lastOperationResult = lastOperationResult
    }

    func withOperationResult(_ result: AssociationOperationResult) -> ExtensionAssociationRow {
        ExtensionAssociationRow(
            rawExtension: rawExtension,
            currentDefaultApp: currentDefaultApp,
            candidateApps: candidateApps,
            isUserAdded: isUserAdded,
            lastOperationResult: result
        )
    }

    static func normalize(_ input: String) -> String? {
        let trimmed = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()

        return trimmed.isEmpty ? nil : trimmed
    }

    private static func makeStatusFlags(for row: ExtensionAssociationRow) -> [AssociationStatusFlag] {
        var flags: [AssociationStatusFlag] = []

        if row.currentDefaultApp == nil {
            flags.append(.noDefaultApp)
        } else if row.currentDefaultApp?.isAvailable == false {
            flags.append(.missingDefaultApp)
        }

        if row.candidateApps.count == 1 {
            flags.append(.singleCandidate)
        }

        if row.candidateApps.count >= manyCandidateThreshold {
            flags.append(.manyCandidates)
        }

        if row.isUserAdded {
            flags.append(.userAddedRule)
        }

        switch row.lastOperationResult {
        case .pendingVerification:
            flags.append(.writePendingVerification)
        case .failed:
            flags.append(.writeFailed)
        case .idle, .succeeded:
            break
        }

        return flags
    }
}
