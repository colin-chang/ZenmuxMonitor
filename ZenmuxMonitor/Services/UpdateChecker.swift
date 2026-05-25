import AppKit
import Foundation

struct GitHubRelease: Decodable {
    let tagName: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}

@MainActor
@Observable
final class UpdateChecker {
    var isChecking = false
    var isUpdating = false
    var latestRelease: GitHubRelease?
    var updateAvailable = false
    var errorMessage: String?

    private let repo = "colin-chang/ZenmuxMonitor"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    func checkForUpdates() async {
        guard !isChecking else { return }
        isChecking = true
        errorMessage = nil
        latestRelease = nil
        updateAvailable = false

        do {
            let url = URL(string: "https://github.com/\(repo)/releases.atom")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw UpdateError.networkError
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw UpdateError.httpError(statusCode: http.statusCode, body: body)
            }

            guard let release = parseAtomFeed(data: data) else {
                throw UpdateError.invalidFeed
            }

            let tag = release.tagName
            let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            updateAvailable = isRemoteNewer(remote: remote, local: currentVersion)
            latestRelease = release
        } catch {
            errorMessage = error.localizedDescription
        }

        isChecking = false
    }

    private func parseAtomFeed(data: Data) -> GitHubRelease? {
        guard let doc = try? XMLDocument(data: data),
              let root = doc.rootElement() else { return nil }

        guard let firstEntry = root.elements(forName: "entry").first,
              let tagName = firstEntry.elements(forName: "title").first?.stringValue,
              !tagName.isEmpty else { return nil }

        var htmlUrl = ""
        for link in firstEntry.elements(forName: "link") {
            if link.attribute(forName: "rel")?.stringValue == "alternate",
               let href = link.attribute(forName: "href")?.stringValue {
                htmlUrl = href
                break
            }
        }

        return GitHubRelease(tagName: tagName, htmlUrl: htmlUrl)
    }

    func downloadAndInstall() async throws {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil

        do {
            guard let release = latestRelease else { return }

            let downloadURL = URL(string: "https://github.com/\(repo)/releases/download/\(release.tagName)/ZenMuxMonitor-\(release.tagName).dmg")!

            let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("ZenmuxMonitor_Update")
            try? FileManager.default.removeItem(at: tmpDir)
            try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

            let dmgPath = tmpDir.appendingPathComponent("ZenMuxMonitor-\(release.tagName).dmg")

            let (tmpURL, _) = try await URLSession.shared.download(from: downloadURL)
            try FileManager.default.moveItem(at: tmpURL, to: dmgPath)

            try mountAndReplace(dmgPath: dmgPath, mountPoint: tmpDir.appendingPathComponent("mount"))
        } catch {
            isUpdating = false
            throw error
        }
    }

    private func mountAndReplace(dmgPath: URL, mountPoint: URL) throws {
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)

        let mount = Process()
        mount.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mount.arguments = ["attach", dmgPath.path, "-mountpoint", mountPoint.path, "-nobrowse", "-quiet"]
        try mount.run()
        mount.waitUntilExit()

        guard mount.terminationStatus == 0 else {
            throw UpdateError.mountFailed
        }

        let mountedApps = try FileManager.default.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "app" }

        guard let newApp = mountedApps.first else {
            throw UpdateError.appNotFoundInDmg
        }

        let currentApp = Bundle.main.bundleURL
        let scriptContent = """
        #!/bin/bash
        set -e
        PID=\(ProcessInfo.processInfo.processIdentifier)
        while kill -0 $PID 2>/dev/null; do sleep 0.5; done
        ditto "\(newApp.path)" "\(currentApp.path)"
        hdiutil detach "\(mountPoint.path)" -quiet || true
        open "\(currentApp.path)"
        rm -f "$0"
        """

        let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("zenmux_update.sh")
        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)

        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["+x", scriptPath.path]
        try chmod.run()
        chmod.waitUntilExit()
        guard chmod.terminationStatus == 0 else {
            throw UpdateError.mountFailed
        }

        let runner = Process()
        runner.executableURL = URL(fileURLWithPath: "/bin/bash")
        runner.arguments = [scriptPath.path]
        try runner.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    private func isRemoteNewer(remote: String, local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}

enum UpdateError: LocalizedError {
    case networkError
    case httpError(statusCode: Int, body: String)
    case invalidFeed
    case mountFailed
    case appNotFoundInDmg

    var errorDescription: String? {
        switch self {
        case .networkError: return L("update.error.network")
        case .httpError(let code, let body):
            let detail = body.isEmpty ? "HTTP \(code)" : "HTTP \(code): \(body.prefix(200))"
            return "\(L("update.error.network")) (\(detail))"
        case .invalidFeed: return L("update.error.feed")
        case .mountFailed: return L("update.error.mount_failed")
        case .appNotFoundInDmg: return L("update.error.app_not_found")
        }
    }
}
