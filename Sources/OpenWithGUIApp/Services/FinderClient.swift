import Foundation

struct FinderClient: Sendable {
    var relaunchHandler: @Sendable () -> Void

    static let live = FinderClient {
        runQuietly("/usr/bin/qlmanage", arguments: ["-r"])
        runQuietly("/usr/bin/qlmanage", arguments: ["-r", "cache"])
        runQuietly("/usr/bin/killall", arguments: ["-q", "QuickLookUIService"])
        runQuietly("/usr/bin/killall", arguments: ["-q", "com.apple.quicklook.ThumbnailsAgent"])
        runQuietly("/usr/bin/killall", arguments: ["-q", "iconservicesagent"])
        runQuietly("/usr/bin/killall", arguments: ["-q", "IconServicesAgent"])
        runQuietly("/usr/bin/killall", arguments: ["-q", "Finder"])
        runQuietly("/usr/bin/killall", arguments: ["-q", "Dock"])
    }

    func relaunch() {
        relaunchHandler()
    }

    private static func runQuietly(_ executablePath: String, arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}
