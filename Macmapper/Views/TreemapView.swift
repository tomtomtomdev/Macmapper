//
//  TreemapView.swift
//  Macmapper
//

import SwiftUI

struct TreemapView: View {
    let item: DirectoryItem
    @Binding var selectedPath: [DirectoryItem]

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb navigation
            BreadcrumbView(path: selectedPath, onSelect: navigateTo)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

            // Treemap content
            GeometryReader { geometry in
                if let current = selectedPath.last ?? Optional(item),
                   let children = current.children, !children.isEmpty {
                    TreemapLayout(items: children, size: geometry.size, onTap: drillDown)
                } else {
                    VStack {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No subdirectories")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func navigateTo(_ item: DirectoryItem) {
        if let index = selectedPath.firstIndex(where: { $0.id == item.id }) {
            selectedPath = Array(selectedPath.prefix(through: index))
        }
    }

    private func drillDown(_ item: DirectoryItem) {
        if item.children != nil && !(item.children?.isEmpty ?? true) {
            selectedPath.append(item)
        }
    }
}

struct BreadcrumbView: View {
    let path: [DirectoryItem]
    let onSelect: (DirectoryItem) -> Void

    var body: some View {
        HStack(spacing: 4) {
            if path.isEmpty {
                Text("Root")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(path.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(item.name) {
                        onSelect(item)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(index == path.count - 1 ? .primary : .accentColor)
                }
            }

            Spacer()
        }
    }
}

struct TreemapLayout: View {
    let items: [DirectoryItem]
    let size: CGSize
    let onTap: (DirectoryItem) -> Void

    private var rects: [(DirectoryItem, CGRect)] {
        squarify(items: items, in: CGRect(origin: .zero, size: size))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(rects, id: \.0.id) { item, rect in
                TreemapCell(item: item, rect: rect, onTap: onTap)
            }
        }
    }

    // Squarified treemap algorithm
    private func squarify(items: [DirectoryItem], in rect: CGRect) -> [(DirectoryItem, CGRect)] {
        guard !items.isEmpty else { return [] }

        let totalSize = items.reduce(0) { $0 + $1.size }
        guard totalSize > 0 else { return [] }

        var result: [(DirectoryItem, CGRect)] = []
        var remaining = items.sorted { $0.size > $1.size }
        var currentRect = rect

        while !remaining.isEmpty {
            let (row, rest) = layoutRow(items: remaining, in: currentRect, totalSize: totalSize)
            result.append(contentsOf: row)
            remaining = rest

            // Calculate remaining rectangle
            if !row.isEmpty {
                let rowSize = row.reduce(0) { $0 + $1.0.size }
                let ratio = CGFloat(rowSize) / CGFloat(totalSize)

                if currentRect.width > currentRect.height {
                    let width = currentRect.width * ratio
                    currentRect = CGRect(
                        x: currentRect.minX + width,
                        y: currentRect.minY,
                        width: currentRect.width - width,
                        height: currentRect.height
                    )
                } else {
                    let height = currentRect.height * ratio
                    currentRect = CGRect(
                        x: currentRect.minX,
                        y: currentRect.minY + height,
                        width: currentRect.width,
                        height: currentRect.height - height
                    )
                }
            }
        }

        return result
    }

    private func layoutRow(items: [DirectoryItem], in rect: CGRect, totalSize: Int64) -> ([(DirectoryItem, CGRect)], [DirectoryItem]) {
        guard let first = items.first else { return ([], []) }

        var row: [DirectoryItem] = [first]
        var remaining = Array(items.dropFirst())

        // Simple split: take items until aspect ratio gets worse
        let isHorizontal = rect.width > rect.height

        var result: [(DirectoryItem, CGRect)] = []
        let rowSize = row.reduce(0) { $0 + $1.size }
        let ratio = CGFloat(rowSize) / CGFloat(totalSize)

        if isHorizontal {
            let width = rect.width * ratio
            var y = rect.minY
            for item in row {
                let itemRatio = CGFloat(item.size) / CGFloat(rowSize)
                let height = rect.height * itemRatio
                result.append((item, CGRect(x: rect.minX, y: y, width: width, height: height)))
                y += height
            }
        } else {
            let height = rect.height * ratio
            var x = rect.minX
            for item in row {
                let itemRatio = CGFloat(item.size) / CGFloat(rowSize)
                let width = rect.width * itemRatio
                result.append((item, CGRect(x: x, y: rect.minY, width: width, height: height)))
                x += width
            }
        }

        return (result, remaining)
    }
}

struct TreemapCell: View {
    let item: DirectoryItem
    let rect: CGRect
    let onTap: (DirectoryItem) -> Void

    @State private var isHovered = false

    private var cellColor: Color {
        switch SizeFormatter.sizeTier(bytes: item.size) {
        case 0: return .green
        case 1: return .blue
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    private var categoryColor: Color {
        switch item.folderCategory {
        case .cleanable: return .green
        case .userContent: return .blue
        case .systemCritical: return .red
        }
    }

    var body: some View {
        Rectangle()
            .fill(cellColor.opacity(isHovered ? 0.8 : 0.6))
            .frame(width: max(0, rect.width - 2), height: max(0, rect.height - 2))
            .overlay(alignment: .topLeading) {
                // Category indicator in top-left corner
                if rect.width > 20 && rect.height > 20 {
                    Image(systemName: item.folderCategory.flagIcon)
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(categoryColor.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .padding(2)
                }
            }
            .overlay(
                VStack {
                    if rect.width > 60 && rect.height > 40 {
                        Text(item.name)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text(SizeFormatter.format(item.size))
                            .font(.caption2)
                    } else if rect.width > 30 && rect.height > 20 {
                        Text(item.name.prefix(10))
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(.white)
                .shadow(radius: 1)
                .padding(4)
            )
            .offset(x: rect.minX + 1, y: rect.minY + 1)
            .onHover { isHovered = $0 }
            .onTapGesture {
                onTap(item)
            }
            .help("\(item.name)\n\(SizeFormatter.format(item.size))\n\(item.folderCategory.tooltip)")
    }
}
