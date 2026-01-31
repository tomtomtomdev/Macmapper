//
//  DirectoryItem.swift
//  Macmapper
//

import Foundation

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
