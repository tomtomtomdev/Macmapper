# Macmapper

A native macOS disk usage analyzer built with SwiftUI. Visualize what's taking up space on your drive with an interactive list or treemap view.

## Features

- **Progressive Scanning** - See results immediately as folders are discovered, with throttled UI updates for smooth performance
- **Dual View Modes**
  - **List View** - Hierarchical expandable list sorted by size
  - **Treemap View** - Visual representation with color-coded size tiers and drill-down navigation
- **Quick Access Sidebar** - One-click scanning for Home, Applications, Downloads, Documents, Desktop, and Library
- **Scan History** - Recent scans are saved for quick re-access
- **Search & Filter** - Find files by name and filter by minimum size (1MB to 1GB thresholds)
- **CSV Export** - Export scan results for further analysis
- **App Bundle Detection** - Recognizes `.app` bundles and calculates their total size without exposing internals

## Screenshots

*List view showing folder hierarchy sorted by size*

*Treemap view with color-coded size visualization*

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Macmapper.git
   cd Macmapper
   ```

2. Open in Xcode:
   ```bash
   open Macmapper.xcodeproj
   ```

3. Build and run (⌘R)

## Usage

1. **Select a folder** - Click "Select Folder" in the toolbar or choose from Quick Access in the sidebar
2. **Watch results appear** - Folders and sizes display progressively as they're scanned
3. **Explore** - Expand folders in list view or click to drill down in treemap view
4. **Filter** - Use the search field or size filter to find specific items
5. **Export** - Save results as CSV with ⌘E

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open folder | ⌘O |
| Export CSV | ⌘E |

## Architecture

```
Macmapper/
├── MacmapperApp.swift      # App entry point
├── ContentView.swift       # Main view with toolbar and content switching
├── Models/
│   ├── DirectoryItem.swift # File/folder data model
│   └── ScanHistory.swift   # Persistent scan history
├── Views/
│   ├── DirectoryListView.swift  # Hierarchical list view
│   ├── DirectoryRowView.swift   # Individual row in list
│   ├── TreemapView.swift        # Squarified treemap visualization
│   └── SidebarView.swift        # Quick access and history sidebar
├── Services/
│   ├── DiskScanner.swift   # Async disk scanning with progressive updates
│   └── AppDetector.swift   # App bundle detection
└── Utilities/
    └── SizeFormatter.swift # Human-readable size formatting
```

## How It Works

### Progressive Scanning

Unlike traditional disk analyzers that wait until scanning completes, Macmapper shows results immediately:

1. Top-level folders appear within ~300ms of starting a scan
2. Sizes update progressively as subfolders complete
3. UI updates are throttled to prevent jank
4. Folders automatically sort by size as data comes in

### Treemap Visualization

The treemap uses a squarified algorithm for optimal rectangle aspect ratios. Colors indicate size tiers:
- Green: Small files
- Blue: Medium files
- Yellow: Large files
- Orange: Very large files
- Red: Huge files

## Privacy

Macmapper runs entirely locally. No data is sent anywhere. The app requires read-only access to selected folders via macOS sandbox permissions.

## License

MIT License - See [LICENSE](LICENSE) for details.
