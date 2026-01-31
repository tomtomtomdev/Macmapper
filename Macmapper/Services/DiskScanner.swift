//
//  DiskScanner.swift
//  Macmapper
//

import Foundation
import AppKit
import Combine

@MainActor
class DiskScanner: ObservableObject {
    @Published var rootItem: DirectoryItem?
    @Published var isScanning: Bool = false
    @Published var scannedCount: Int = 0
    @Published var currentPath: String = ""
    @Published var elapsedTime: TimeInterval = 0
    @Published var errorMessage: String?

    private var scanTask: Task<Void, Never>?
    private var startTime: Date?
    private var timer: Timer?

    // Throttle properties for progressive updates
    private var lastUpdateTime: Date = .distantPast
    private let updateInterval: TimeInterval = 0.3  // 300ms throttle

    func scan(url: URL) {
        cancel()

        isScanning = true
        scannedCount = 0
        currentPath = ""
        elapsedTime = 0
        errorMessage = nil
        rootItem = nil
        startTime = Date()
        lastUpdateTime = .distantPast

        // Start elapsed time timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if let start = self?.startTime {
                    self?.elapsedTime = Date().timeIntervalSince(start)
                }
            }
        }

        scanTask = Task {
            do {
                let result = try await scanDirectoryProgressive(url: url, isRoot: true)
                // Final update with isScanning = false
                var mutableResult = result
                mutableResult.isScanning = false
                mutableResult.sortChildrenBySize()
                mutableResult.calculatePercentages()
                self.rootItem = mutableResult
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                }
            }

            self.timer?.invalidate()
            self.timer = nil
            self.isScanning = false
        }
    }

    func cancel() {
        scanTask?.cancel()
        scanTask = nil
        timer?.invalidate()
        timer = nil
        isScanning = false
    }

    /// Progressive scan that publishes partial results for immediate UI feedback
    private func scanDirectoryProgressive(url: URL, isRoot: Bool) async throws -> DirectoryItem {
        try Task.checkCancellation()

        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .isPackageKey]

        // Update current path on main thread
        currentPath = url.path
        scannedCount += 1

        var totalSize: Int64 = 0
        var children: [DirectoryItem] = []

        // Check if this is an app bundle
        let isPackage = (try? url.resourceValues(forKeys: [.isPackageKey]).isPackage) ?? false

        if isPackage {
            // For app bundles, just calculate total size without exposing internals
            totalSize = calculateBundleSize(url: url)
            return DirectoryItem(
                url: url,
                name: url.lastPathComponent,
                size: totalSize,
                children: nil,
                isApp: url.pathExtension == "app"
            )
        }

        var subdirectories: [URL] = []

        // First pass: get immediate directory contents
        let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        )

        for itemURL in contents ?? [] {
            try Task.checkCancellation()

            let resourceValues = try? itemURL.resourceValues(forKeys: resourceKeys)
            let isDirectory = resourceValues?.isDirectory ?? false
            let isPackage = resourceValues?.isPackage ?? false

            if isDirectory && !isPackage {
                subdirectories.append(itemURL)
            } else {
                let size: Int64
                if isPackage {
                    size = calculateBundleSize(url: itemURL)
                } else {
                    size = Int64(resourceValues?.fileSize ?? 0)
                }

                let child = DirectoryItem(
                    url: itemURL,
                    name: itemURL.lastPathComponent,
                    size: size,
                    children: isPackage ? nil : nil,
                    isApp: itemURL.pathExtension == "app"
                )
                children.append(child)
                totalSize += size
            }
        }

        // For root level, add placeholder items for subdirectories to show them immediately
        if isRoot {
            for subdir in subdirectories {
                let placeholder = DirectoryItem(
                    url: subdir,
                    name: subdir.lastPathComponent,
                    size: 0,
                    children: [],
                    isScanning: true
                )
                children.append(placeholder)
            }

            // Publish initial state showing all top-level items
            let initialRoot = DirectoryItem(
                url: url,
                name: url.lastPathComponent,
                size: totalSize,
                children: children,
                isScanning: true
            )
            publishPartialResults(initialRoot)
        }

        // Recursively scan subdirectories
        for subdir in subdirectories {
            try Task.checkCancellation()
            let child = try await scanDirectoryProgressive(url: subdir, isRoot: false)

            if isRoot {
                // Replace placeholder with actual scanned result
                // Find the placeholder by URL
                if let placeholderIndex = children.firstIndex(where: { $0.url == subdir }) {
                    children[placeholderIndex] = child
                } else {
                    children.append(child)
                }
                totalSize += child.size

                // Publish partial results after each top-level child completes
                let partialRoot = DirectoryItem(
                    url: url,
                    name: url.lastPathComponent,
                    size: totalSize,
                    children: children,
                    isScanning: true
                )
                publishPartialResults(partialRoot)
            } else {
                children.append(child)
                totalSize += child.size
            }
        }

        return DirectoryItem(
            url: url,
            name: url.lastPathComponent,
            size: totalSize,
            children: children
        )
    }

    /// Publish partial results with throttling to avoid UI jank
    private func publishPartialResults(_ partialItem: DirectoryItem) {
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) >= updateInterval else { return }
        lastUpdateTime = now

        var item = partialItem
        item.sortChildrenBySize()
        item.calculatePercentages()
        self.rootItem = item
    }

    private func calculateBundleSize(url: URL) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }

        return totalSize
    }
}
