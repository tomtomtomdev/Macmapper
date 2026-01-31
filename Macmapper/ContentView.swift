//
//  ContentView.swift
//  Macmapper
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var scanner = DiskScanner()
    @StateObject private var history = ScanHistory()

    @State private var searchText = ""
    @State private var minSizeFilter: Int64 = 0
    @State private var viewMode: ViewMode = .list
    @State private var treemapPath: [DirectoryItem] = []
    @State private var showExportDialog = false
    @State private var historyTask: Task<Void, Never>?

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case treemap = "Treemap"

        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .treemap: return "square.grid.2x2"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(history: history, onSelectPath: startScan)
                .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                // Toolbar
                toolbarView
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Main content
                mainContentView
            }
        }
        .navigationTitle("Macmapper")
        .frame(minWidth: 800, minHeight: 600)
        .alert("Error", isPresented: .constant(scanner.errorMessage != nil)) {
            Button("OK") {
                scanner.errorMessage = nil
            }
        } message: {
            if let error = scanner.errorMessage {
                Text(error)
            }
        }
        .fileExporter(
            isPresented: $showExportDialog,
            document: CSVDocument(items: scanner.rootItem),
            contentType: .commaSeparatedText,
            defaultFilename: "disk-usage.csv"
        ) { result in
            // Handle export result
        }
    }

    @ViewBuilder
    private var toolbarView: some View {
        HStack(spacing: 16) {
            // Select folder button
            Button {
                selectFolder()
            } label: {
                Label("Select Folder", systemImage: "folder.badge.plus")
            }
            .keyboardShortcut("o", modifiers: .command)

            // Scan status
            if scanner.isScanning {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Scanning: \(scanner.scannedCount) items")
                            .font(.caption)
                        Text(scanner.currentPath)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 200)
                    }

                    Text(formatElapsed(scanner.elapsedTime))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Cancel") {
                        scanner.cancel()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()

            // Search
            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            // Size filter
            Picker("Min Size", selection: $minSizeFilter) {
                Text("All").tag(Int64(0))
                Text("> 1 MB").tag(Int64(1_000_000))
                Text("> 10 MB").tag(Int64(10_000_000))
                Text("> 100 MB").tag(Int64(100_000_000))
                Text("> 1 GB").tag(Int64(1_000_000_000))
            }
            .frame(width: 120)

            // View mode toggle
            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)

            // Export button
            Button {
                showExportDialog = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(scanner.rootItem == nil)
            .keyboardShortcut("e", modifiers: .command)
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        if let rootItem = scanner.rootItem {
            // Show results (works for both complete and partial scans)
            Group {
                switch viewMode {
                case .list:
                    DirectoryListView(
                        item: rootItem,
                        maxSize: rootItem.size,
                        searchText: $searchText,
                        minSizeFilter: $minSizeFilter
                    )
                case .treemap:
                    TreemapView(item: rootItem, selectedPath: $treemapPath)
                }
            }
        } else if scanner.isScanning {
            // Only show full-screen spinner if no partial data yet
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Scanning...")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)

                Text("Macmapper")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Select a folder to analyze disk usage")
                    .foregroundColor(.secondary)

                Button {
                    selectFolder()
                } label: {
                    Label("Select Folder", systemImage: "folder.badge.plus")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Or choose from Quick Access in the sidebar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to analyze"
        panel.prompt = "Analyze"

        if panel.runModal() == .OK, let url = panel.url {
            startScan(url: url)
        }
    }

    private func startScan(url: URL) {
        treemapPath = []
        historyTask?.cancel()
        scanner.scan(url: url)

        // Save to history when scan completes
        historyTask = Task {
            // Wait for scan to complete
            while scanner.isScanning {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            guard !Task.isCancelled else { return }

            if let root = scanner.rootItem {
                history.add(
                    path: url.path,
                    size: root.size,
                    itemCount: scanner.scannedCount
                )
            }
        }
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        }
        return String(format: "0:%02d", secs)
    }
}

// MARK: - CSV Export

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var items: DirectoryItem?

    init(items: DirectoryItem?) {
        self.items = items
    }

    init(configuration: ReadConfiguration) throws {
        items = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var csv = "Path,Name,Size (bytes),Size (formatted)\n"

        if let root = items {
            csv += buildCSV(item: root)
        }

        let data = csv.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }

    private func buildCSV(item: DirectoryItem) -> String {
        var result = "\"\(item.url.path)\",\"\(item.name)\",\(item.size),\"\(SizeFormatter.format(item.size))\"\n"

        for child in item.children ?? [] {
            result += buildCSV(item: child)
        }

        return result
    }
}

import UniformTypeIdentifiers

#Preview {
    ContentView()
}
