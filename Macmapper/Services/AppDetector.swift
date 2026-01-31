//
//  AppDetector.swift
//  Macmapper
//

import Foundation
import AppKit

struct AppDetector {
    /// Check if URL is a macOS app bundle
    static func isAppBundle(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "app"
    }

    /// Get the app icon for a bundle
    static func appIcon(for url: URL) -> NSImage? {
        guard isAppBundle(url) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    /// Get app info from bundle
    static func appInfo(for url: URL) -> AppInfo? {
        guard isAppBundle(url) else { return nil }

        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")

        guard let data = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }

        return AppInfo(
            name: plist["CFBundleName"] as? String ?? url.deletingPathExtension().lastPathComponent,
            bundleIdentifier: plist["CFBundleIdentifier"] as? String,
            version: plist["CFBundleShortVersionString"] as? String,
            build: plist["CFBundleVersion"] as? String
        )
    }

    /// Get system icon for file type
    static func icon(for url: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

struct AppInfo {
    let name: String
    let bundleIdentifier: String?
    let version: String?
    let build: String?

    var displayVersion: String {
        if let version = version, let build = build {
            return "\(version) (\(build))"
        }
        return version ?? build ?? "Unknown"
    }
}
