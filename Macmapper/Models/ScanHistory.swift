//
//  ScanHistory.swift
//  Macmapper
//

import Foundation
import Combine

struct ScanHistoryItem: Identifiable, Codable {
    let id: UUID
    let path: String
    let size: Int64
    let scanDate: Date
    let itemCount: Int

    init(path: String, size: Int64, itemCount: Int) {
        self.id = UUID()
        self.path = path
        self.size = size
        self.scanDate = Date()
        self.itemCount = itemCount
    }
}

class ScanHistory: ObservableObject {
    @Published var items: [ScanHistoryItem] = []

    private let key = "ScanHistory"
    private let maxItems = 20

    init() {
        load()
    }

    func add(path: String, size: Int64, itemCount: Int) {
        let item = ScanHistoryItem(path: path, size: size, itemCount: itemCount)

        // Remove existing entry for same path
        items.removeAll { $0.path == path }

        // Add new item at beginning
        items.insert(item, at: 0)

        // Trim to max items
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        save()
    }

    func remove(_ item: ScanHistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items = []
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ScanHistoryItem].self, from: data) {
            items = decoded
        }
    }
}
