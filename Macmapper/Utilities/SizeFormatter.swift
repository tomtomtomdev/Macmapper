//
//  SizeFormatter.swift
//  Macmapper
//

import Foundation

struct SizeFormatter {
    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter
    }()

    /// Format bytes to human-readable string (e.g., "1.5 GB")
    static func format(_ bytes: Int64) -> String {
        formatter.string(fromByteCount: bytes)
    }

    /// Format with specific precision
    static func format(_ bytes: Int64, decimals: Int) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1000 && unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(value)) \(units[unitIndex])"
        }

        return String(format: "%.\(decimals)f %@", value, units[unitIndex])
    }

    /// Get color tier based on size (0 = smallest, 4 = largest)
    static func sizeTier(bytes: Int64) -> Int {
        switch bytes {
        case ..<1_000_000:          // < 1 MB
            return 0
        case ..<100_000_000:        // < 100 MB
            return 1
        case ..<1_000_000_000:      // < 1 GB
            return 2
        case ..<10_000_000_000:     // < 10 GB
            return 3
        default:                     // >= 10 GB
            return 4
        }
    }
}
