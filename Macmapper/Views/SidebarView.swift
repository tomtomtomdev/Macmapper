//
//  SidebarView.swift
//  Macmapper
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var history: ScanHistory
    let onSelectPath: (URL) -> Void

    private let commonLocations: [(name: String, icon: String, path: URL?)] = [
        ("Home", "house.fill", FileManager.default.homeDirectoryForCurrentUser),
        ("Applications", "app.badge.fill", URL(fileURLWithPath: "/Applications")),
        ("Downloads", "arrow.down.circle.fill", FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first),
        ("Documents", "doc.fill", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first),
        ("Desktop", "menubar.dock.rectangle", FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first),
        ("Library", "books.vertical.fill", FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first)
    ]

    var body: some View {
        List {
            Section("Quick Access") {
                ForEach(commonLocations, id: \.name) { location in
                    if let path = location.path {
                        Button {
                            onSelectPath(path)
                        } label: {
                            Label(location.name, systemImage: location.icon)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Recent Scans") {
                if history.items.isEmpty {
                    Text("No recent scans")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(history.items) { item in
                        Button {
                            onSelectPath(URL(fileURLWithPath: item.path))
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(URL(fileURLWithPath: item.path).lastPathComponent)
                                    .lineLimit(1)
                                HStack {
                                    Text(SizeFormatter.format(item.size))
                                    Text("•")
                                    Text(item.scanDate, style: .relative)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Remove from History", role: .destructive) {
                                history.remove(item)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Clear History", role: .destructive) {
                    history.clear()
                }
                .disabled(history.items.isEmpty)
            }
        }
        .listStyle(.sidebar)
    }
}
