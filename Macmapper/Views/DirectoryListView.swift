//
//  DirectoryListView.swift
//  Macmapper
//

import SwiftUI

struct DirectoryListView: View {
    let item: DirectoryItem
    let maxSize: Int64
    @Binding var searchText: String
    @Binding var minSizeFilter: Int64

    var body: some View {
        List {
            DirectoryTreeNode(
                item: item,
                maxSize: maxSize,
                searchText: searchText,
                minSizeFilter: minSizeFilter,
                depth: 0
            )
        }
        .listStyle(.inset)
    }
}

struct DirectoryTreeNode: View {
    let item: DirectoryItem
    let maxSize: Int64
    let searchText: String
    let minSizeFilter: Int64
    let depth: Int

    @State private var isExpanded: Bool = false

    private var filteredChildren: [DirectoryItem]? {
        guard let children = item.children else { return nil }

        return children.filter { child in
            // Size filter
            guard child.size >= minSizeFilter else { return false }

            // Search filter (if searching, show items that match or have matching descendants)
            if !searchText.isEmpty {
                return matchesSearch(child)
            }

            return true
        }
    }

    private func matchesSearch(_ item: DirectoryItem) -> Bool {
        if item.name.localizedCaseInsensitiveContains(searchText) {
            return true
        }

        // Check children recursively
        if let children = item.children {
            return children.contains { matchesSearch($0) }
        }

        return false
    }

    var body: some View {
        if let children = filteredChildren, !children.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(children) { child in
                    DirectoryTreeNode(
                        item: child,
                        maxSize: item.size,
                        searchText: searchText,
                        minSizeFilter: minSizeFilter,
                        depth: depth + 1
                    )
                }
            } label: {
                rowContent
            }
            .contextMenu {
                contextMenuItems
            }
        } else {
            rowContent
                .contextMenu {
                    contextMenuItems
                }
        }
    }

    private var rowContent: some View {
        DirectoryRowView(item: item, maxSize: maxSize)
            .background(highlightIfMatch)
    }

    @ViewBuilder
    private var highlightIfMatch: some View {
        if !searchText.isEmpty && item.name.localizedCaseInsensitiveContains(searchText) {
            Color.yellow.opacity(0.2)
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Reveal in Finder") {
            NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path)
        }

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url.path, forType: .string)
        }

        Divider()

        Button("Move to Trash", role: .destructive) {
            moveToTrash()
        }
    }

    private func moveToTrash() {
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
        } catch {
            // Error handling would show an alert in production
            print("Failed to move to trash: \(error.localizedDescription)")
        }
    }
}
