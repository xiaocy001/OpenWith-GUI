import Foundation

protocol AssociationRepository: Sendable {
    func loadRows() async throws -> [ExtensionAssociationRow]
    func refreshRows(for normalizedExtensions: [String]) async throws -> [ExtensionAssociationRow]
    func loadAppChoices() async throws -> [AppDescriptor]
    func addUserExtension(_ rawExtension: String) async throws -> String
}
