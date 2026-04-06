import Foundation

enum AssociationStatusFlag: String, CaseIterable, Hashable, Sendable {
    case noDefaultApp
    case missingDefaultApp
    case singleCandidate
    case manyCandidates
    case userAddedRule
    case writePendingVerification
    case writeFailed
}
