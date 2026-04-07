import Foundation

enum AssociationStatusFlag: String, CaseIterable, Hashable, Sendable {
    case noIssues
    case noDefaultApp
    case missingDefaultApp
    case singleCandidate
    case manyCandidates
    case userAddedRule
    case writePendingVerification
    case writeFailed

    var displayTitle: String {
        switch self {
        case .noIssues:
            "No Issues"
        case .noDefaultApp:
            "No Default App"
        case .missingDefaultApp:
            "Missing Default App"
        case .singleCandidate:
            "Single Candidate"
        case .manyCandidates:
            "Many Candidates"
        case .userAddedRule:
            "User Added"
        case .writePendingVerification:
            "Pending Verification"
        case .writeFailed:
            "Write Failed"
        }
    }

    var displaySubtitle: String {
        switch self {
        case .noIssues:
            "Extensions with no special status"
        case .noDefaultApp:
            "Extensions with no current default app"
        case .missingDefaultApp:
            "Default app is recorded but no longer available"
        case .singleCandidate:
            "Only one candidate app is available"
        case .manyCandidates:
            "Five or more candidate apps are available"
        case .userAddedRule:
            "Extension was added manually by the user"
        case .writePendingVerification:
            "Recent app change has not been confirmed yet"
        case .writeFailed:
            "Recent app change failed"
        }
    }
}
