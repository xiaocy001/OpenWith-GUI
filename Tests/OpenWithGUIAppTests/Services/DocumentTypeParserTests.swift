import Foundation
import Testing
@testable import OpenWithGUIApp

struct DocumentTypeParserTests {
    @Test
    func collectsDirectExtensionsAndUTTypeDerivedExtensions() {
        let infoPlist: [String: Any] = [
            "CFBundleDocumentTypes": [
                [
                    "CFBundleTypeExtensions": ["json", "JSON", "*"],
                    "LSItemContentTypes": ["public.yaml"]
                ]
            ]
        ]

        let parser = DocumentTypeParser(
            preferredExtensionForTypeIdentifier: { identifier in
                identifier == "public.yaml" ? "yaml" : nil
            }
        )

        let parsed = parser.extensions(from: infoPlist)

        #expect(parsed == Set(["json", "yaml"]))
    }
}
