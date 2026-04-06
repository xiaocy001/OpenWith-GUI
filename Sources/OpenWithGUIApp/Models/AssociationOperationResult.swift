import Foundation

enum AssociationOperationResult: Equatable, Sendable {
    case idle
    case succeeded(message: String)
    case failed(message: String)
    case pendingVerification(message: String)
}
