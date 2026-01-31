//
//  DirectoryItem.swift
//  Macmapper
//

import Foundation

/// Indicates whether a folder is safe to clean or system-critical
enum FolderCategory {
    case cleanable      // Caches, logs, temp files - safe to delete
    case userContent    // User documents, photos, etc - user decides
    case systemCritical // System files - do not delete

    var flagColor: String {
        switch self {
        case .cleanable: return "green"
        case .userContent: return "blue"
        case .systemCritical: return "red"
        }
    }

    var flagIcon: String {
        switch self {
        case .cleanable: return "flag.fill"
        case .userContent: return "flag"
        case .systemCritical: return "exclamationmark.triangle.fill"
        }
    }

    var tooltip: String {
        switch self {
        case .cleanable: return "Safe to clean (caches, logs, temp files)"
        case .userContent: return "User content"
        case .systemCritical: return "System-critical - do not delete"
        }
    }
}

struct DirectoryItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    var size: Int64  // bytes
    var children: [DirectoryItem]?
    var isApp: Bool = false
    var iconName: String?

    /// Percentage of parent's size (0-100)
    var percentageOfParent: Double = 0

    /// Whether this subtree is still being scanned
    var isScanning: Bool = false

    /// Whether this is a directory (has potential children)
    var isDirectory: Bool {
        children != nil
    }

    /// Categorizes this folder for the cleanup indicator
    var folderCategory: FolderCategory {
        let path = url.path.lowercased()
        let name = self.name.lowercased()

        // Cleanable patterns - caches, logs, temp files
        let cleanablePatterns = [
            "/library/caches",
            "/library/logs",
            "/.cache",
            "/cache",
            "/caches",
            "/logs",
            "/tmp",
            "/temp",
            "/.tmp",
            "/.temp",
            "/deriveddata",
            "/node_modules",
            "/.npm",
            "/.yarn",
            "/pods",
            "/.cocoapods",
            "/build",
            "/.build",
            "/xcuserdata",
            "/.trash",
            "/downloads",
            "/ios device backups",
            "/mobilebackups",
            "/__pycache__",
            "/.gradle",
            "/target"  // Rust/Maven
        ]

        let cleanableNames = [
            "caches", "cache", "logs", "log", "tmp", "temp",
            "node_modules", ".cache", ".npm", ".yarn",
            "deriveddata", "xcuserdata", "__pycache__",
            ".trash", "downloads", "build", ".build"
        ]

        // System-critical patterns
        let systemCriticalPatterns = [
            "/system",
            "/usr",
            "/bin",
            "/sbin",
            "/private/var",
            "/private/etc",
            "/library/frameworks",
            "/library/extensions",
            "/library/kernelcollections",
            "/library/directoryservices",
            "/library/privilegedhelpertools",
            "/applications",  // App bundles themselves
            "/.app/contents"  // Inside app bundles
        ]

        let systemCriticalNames = [
            "system", "usr", "bin", "sbin", "library",
            "frameworks", "extensions", "kernelcollections"
        ]

        // Check cleanable first (more specific)
        for pattern in cleanablePatterns {
            if path.contains(pattern) {
                return .cleanable
            }
        }
        if cleanableNames.contains(name) {
            return .cleanable
        }

        // Check system-critical
        for pattern in systemCriticalPatterns {
            if path.contains(pattern) {
                return .systemCritical
            }
        }
        if systemCriticalNames.contains(name) && path.hasPrefix("/") && !path.contains("/users/") {
            return .systemCritical
        }

        // Apps are system-critical (don't delete randomly)
        if isApp {
            return .systemCritical
        }

        // Default to user content
        return .userContent
    }

    /// Sort children by size (largest first)
    mutating func sortChildrenBySize() {
        children?.sort { $0.size > $1.size }
        for i in children?.indices ?? 0..<0 {
            children?[i].sortChildrenBySize()
        }
    }

    /// Calculate percentages relative to parent size
    mutating func calculatePercentages(parentSize: Int64? = nil) {
        let totalSize = parentSize ?? size
        if totalSize > 0 {
            percentageOfParent = Double(size) / Double(totalSize) * 100
        }
        for i in children?.indices ?? 0..<0 {
            children?[i].calculatePercentages(parentSize: size)
        }
    }
}
