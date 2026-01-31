//
//  DirectoryRowView.swift
//  Macmapper
//

import SwiftUI
import AppKit

struct DirectoryRowView: View {
    let item: DirectoryItem
    let maxSize: Int64
    let showBar: Bool

    init(item: DirectoryItem, maxSize: Int64 = 0, showBar: Bool = true) {
        self.item = item
        self.maxSize = maxSize
        self.showBar = showBar
    }

    private var barColor: Color {
        switch SizeFormatter.sizeTier(bytes: item.size) {
        case 0: return .green.opacity(0.3)
        case 1: return .blue.opacity(0.3)
        case 2: return .yellow.opacity(0.3)
        case 3: return .orange.opacity(0.3)
        default: return .red.opacity(0.3)
        }
    }

    private var barWidth: CGFloat {
        guard maxSize > 0 else { return 0 }
        return CGFloat(item.size) / CGFloat(maxSize)
    }

    private var icon: NSImage {
        if item.isApp {
            return AppDetector.appIcon(for: item.url) ?? NSWorkspace.shared.icon(forFile: item.url.path)
        }
        return NSWorkspace.shared.icon(forFile: item.url.path)
    }

    private var categoryColor: Color {
        switch item.folderCategory {
        case .cleanable: return .green
        case .userContent: return .blue
        case .systemCritical: return .red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Category flag (left of icon)
            Image(systemName: item.folderCategory.flagIcon)
                .font(.system(size: 10))
                .foregroundColor(categoryColor)
                .frame(width: 14)
                .help(item.folderCategory.tooltip)

            // File/folder icon
            Image(nsImage: icon)
                .resizable()
                .frame(width: 18, height: 18)

            // Name
            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Percentage (if available)
            if item.percentageOfParent > 0 {
                Text(String(format: "%.1f%%", item.percentageOfParent))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }

            // Size
            Text(SizeFormatter.format(item.size))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .background(
            GeometryReader { geometry in
                if showBar && maxSize > 0 {
                    Rectangle()
                        .fill(barColor)
                        .frame(width: geometry.size.width * barWidth)
                }
            }
        )
    }
}

#Preview {
    VStack {
        DirectoryRowView(
            item: DirectoryItem(
                url: URL(fileURLWithPath: "/Applications/Safari.app"),
                name: "Safari.app",
                size: 1_500_000_000,
                children: nil,
                isApp: true
            ),
            maxSize: 5_000_000_000
        )
        DirectoryRowView(
            item: DirectoryItem(
                url: URL(fileURLWithPath: "/Users/test/Documents"),
                name: "Documents",
                size: 500_000_000,
                children: []
            ),
            maxSize: 5_000_000_000
        )
    }
    .padding()
    .frame(width: 400)
}
