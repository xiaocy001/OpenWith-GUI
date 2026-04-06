import Foundation

struct AssociationWriteResult: Equatable, Sendable {
    let normalizedExtension: String
    let errorMessage: String?
}

protocol AssociationWriter: Sendable {
    func setDefaultApp(_ app: AppDescriptor, for normalizedExtensions: [String]) async throws -> [AssociationWriteResult]
}
