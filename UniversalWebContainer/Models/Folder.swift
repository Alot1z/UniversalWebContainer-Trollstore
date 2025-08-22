import Foundation
import SwiftUI

struct Folder: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: FolderIcon
    var color: FolderColor
    var webAppCount: Int
    var dateCreated: Date
    var dateModified: Date
    var isPinned: Bool
    var isFavorite: Bool
    var sortOrder: SortOrder
    var isAscending: Bool
    var tags: [String]
    var notes: String
    
    init(id: UUID = UUID(), name: String, icon: FolderIcon = .folder, color: FolderColor = .blue, webAppCount: Int = 0, dateCreated: Date = Date(), dateModified: Date = Date(), isPinned: Bool = false, isFavorite: Bool = false, sortOrder: SortOrder = .name, isAscending: Bool = true, tags: [String] = [], notes: String = "") {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.webAppCount = webAppCount
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.isAscending = isAscending
        self.tags = tags
        self.notes = notes
    }
    
    // MARK: - Folder Icon
    enum FolderIcon: String, CaseIterable, Codable {
        case folder = "folder"
        case house = "house"
        case briefcase = "briefcase"
        case heart = "heart"
        case star = "star"
        case bookmark = "bookmark"
        case gamecontroller = "gamecontroller"
        case camera = "camera"
        case music = "music"
        case video = "video"
        case cart = "cart"
        case creditcard = "creditcard"
        case newspaper = "newspaper"
        case envelope = "envelope"
        case message = "message"
        case person = "person"
        case car = "car"
        case airplane = "airplane"
        case leaf = "leaf"
        case flame = "flame"
        case bolt = "bolt"
        case cloud = "cloud"
        case moon = "moon"
        case sun = "sun"
        
        var displayName: String {
            switch self {
            case .folder: return "Folder"
            case .house: return "Home"
            case .briefcase: return "Work"
            case .heart: return "Favorites"
            case .star: return "Starred"
            case .bookmark: return "Bookmarks"
            case .gamecontroller: return "Games"
            case .camera: return "Photos"
            case .music: return "Music"
            case .video: return "Video"
            case .cart: return "Shopping"
            case .creditcard: return "Finance"
            case .newspaper: return "News"
            case .envelope: return "Mail"
            case .message: return "Social"
            case .person: return "Personal"
            case .car: return "Travel"
            case .airplane: return "Travel"
            case .leaf: return "Nature"
            case .flame: return "Hot"
            case .bolt: return "Quick"
            case .cloud: return "Cloud"
            case .moon: return "Night"
            case .sun: return "Day"
            }
        }
    }
    
    // MARK: - Folder Color
    enum FolderColor: String, CaseIterable, Codable {
        case blue = "blue"
        case red = "red"
        case green = "green"
        case orange = "orange"
        case purple = "purple"
        case pink = "pink"
        case yellow = "yellow"
        case gray = "gray"
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .red: return .red
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            case .pink: return .pink
            case .yellow: return .yellow
            case .gray: return .gray
            }
        }
        
        var displayName: String {
            switch self {
            case .blue: return "Blue"
            case .red: return "Red"
            case .green: return "Green"
            case .orange: return "Orange"
            case .purple: return "Purple"
            case .pink: return "Pink"
            case .yellow: return "Yellow"
            case .gray: return "Gray"
            }
        }
    }
    
    // MARK: - Sort Order
    enum SortOrder: String, CaseIterable, Codable {
        case name = "name"
        case dateAdded = "dateAdded"
        case lastAccessed = "lastAccessed"
        case accessCount = "accessCount"
        case domain = "domain"
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .dateAdded: return "Date Added"
            case .lastAccessed: return "Last Accessed"
            case .accessCount: return "Access Count"
            case .domain: return "Domain"
            }
        }
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        return name.isEmpty ? "Untitled Folder" : name
    }
    
    var isEmpty: Bool {
        return webAppCount == 0
    }
    
    var isRecentlyModified: Bool {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dateModified > oneWeekAgo
    }
    
    var isRecentlyCreated: Bool {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dateCreated > oneWeekAgo
    }
    
    // MARK: - Methods
    mutating func updateWebAppCount(_ count: Int) {
        webAppCount = count
        dateModified = Date()
    }
    
    mutating func incrementWebAppCount() {
        webAppCount += 1
        dateModified = Date()
    }
    
    mutating func decrementWebAppCount() {
        webAppCount = max(0, webAppCount - 1)
        dateModified = Date()
    }
    
    mutating func togglePin() {
        isPinned.toggle()
        dateModified = Date()
    }
    
    mutating func toggleFavorite() {
        isFavorite.toggle()
        dateModified = Date()
    }
    
    mutating func updateSortOrder(_ newSortOrder: SortOrder) {
        sortOrder = newSortOrder
        dateModified = Date()
    }
    
    mutating func toggleSortDirection() {
        isAscending.toggle()
        dateModified = Date()
    }
    
    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            dateModified = Date()
        }
    }
    
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        dateModified = Date()
    }
    
    mutating func updateNotes(_ newNotes: String) {
        notes = newNotes
        dateModified = Date()
    }
    
    mutating func updateIcon(_ newIcon: FolderIcon) {
        icon = newIcon
        dateModified = Date()
    }
    
    mutating func updateColor(_ newColor: FolderColor) {
        color = newColor
        dateModified = Date()
    }
    
    mutating func rename(_ newName: String) {
        name = newName
        dateModified = Date()
    }
}

// MARK: - Folder Extensions
extension Folder {
    static let sampleFolders: [Folder] = [
        Folder(name: "Work", icon: .briefcase, color: .blue, webAppCount: 5),
        Folder(name: "Social", icon: .message, color: .pink, webAppCount: 8),
        Folder(name: "Entertainment", icon: .video, color: .purple, webAppCount: 12),
        Folder(name: "Shopping", icon: .cart, color: .orange, webAppCount: 3),
        Folder(name: "Finance", icon: .creditcard, color: .green, webAppCount: 4),
        Folder(name: "News", icon: .newspaper, color: .red, webAppCount: 6),
        Folder(name: "Games", icon: .gamecontroller, color: .yellow, webAppCount: 7),
        Folder(name: "Personal", icon: .person, color: .gray, webAppCount: 9)
    ]
    
    static func createSampleFolder(name: String, icon: FolderIcon = .folder, color: FolderColor = .blue) -> Folder {
        return Folder(
            name: name,
            icon: icon,
            color: color,
            webAppCount: 0
        )
    }
}

// MARK: - Folder Sorting
extension Folder {
    enum SortOption {
        case name
        case dateCreated
        case dateModified
        case webAppCount
        case isPinned
        case isFavorite
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .dateCreated: return "Date Created"
            case .dateModified: return "Date Modified"
            case .webAppCount: return "Web App Count"
            case .isPinned: return "Pinned"
            case .isFavorite: return "Favorite"
            }
        }
    }
    
    static func sorted(_ folders: [Folder], by sortOption: SortOption, ascending: Bool = true) -> [Folder] {
        return folders.sorted { first, second in
            let result: Bool
            switch sortOption {
            case .name:
                result = first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            case .dateCreated:
                result = first.dateCreated < second.dateCreated
            case .dateModified:
                result = first.dateModified < second.dateModified
            case .webAppCount:
                result = first.webAppCount < second.webAppCount
            case .isPinned:
                result = first.isPinned && !second.isPinned
            case .isFavorite:
                result = first.isFavorite && !second.isFavorite
            }
            return ascending ? result : !result
        }
    }
}

// MARK: - Folder Filtering
extension Folder {
    enum FilterOption {
        case all
        case pinned
        case favorite
        case empty
        case nonEmpty
        case recentlyModified
        case recentlyCreated
        case withTag(String)
        
        var displayName: String {
            switch self {
            case .all: return "All Folders"
            case .pinned: return "Pinned"
            case .favorite: return "Favorites"
            case .empty: return "Empty"
            case .nonEmpty: return "Non-Empty"
            case .recentlyModified: return "Recently Modified"
            case .recentlyCreated: return "Recently Created"
            case .withTag(let tag): return "Tag: \(tag)"
            }
        }
    }
    
    static func filtered(_ folders: [Folder], by filterOption: FilterOption) -> [Folder] {
        switch filterOption {
        case .all:
            return folders
        case .pinned:
            return folders.filter { $0.isPinned }
        case .favorite:
            return folders.filter { $0.isFavorite }
        case .empty:
            return folders.filter { $0.isEmpty }
        case .nonEmpty:
            return folders.filter { !$0.isEmpty }
        case .recentlyModified:
            return folders.filter { $0.isRecentlyModified }
        case .recentlyCreated:
            return folders.filter { $0.isRecentlyCreated }
        case .withTag(let tag):
            return folders.filter { $0.tags.contains(tag) }
        }
    }
}

// MARK: - Folder Search
extension Folder {
    static func search(_ folders: [Folder], query: String) -> [Folder] {
        guard !query.isEmpty else { return folders }
        
        return folders.filter { folder in
            folder.name.localizedCaseInsensitiveContains(query) ||
            folder.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            folder.notes.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Folder Statistics
extension Folder {
    struct Statistics {
        let totalFolders: Int
        let totalWebApps: Int
        let pinnedFolders: Int
        let favoriteFolders: Int
        let emptyFolders: Int
        let averageWebAppsPerFolder: Double
        let mostUsedColor: FolderColor
        let mostUsedIcon: FolderIcon
        
        init(from folders: [Folder]) {
            totalFolders = folders.count
            totalWebApps = folders.reduce(0) { $0 + $1.webAppCount }
            pinnedFolders = folders.filter { $0.isPinned }.count
            favoriteFolders = folders.filter { $0.isFavorite }.count
            emptyFolders = folders.filter { $0.isEmpty }.count
            averageWebAppsPerFolder = totalFolders > 0 ? Double(totalWebApps) / Double(totalFolders) : 0
            
            // Most used color
            let colorCounts = Dictionary(grouping: folders, by: { $0.color })
                .mapValues { $0.count }
            mostUsedColor = colorCounts.max(by: { $0.value < $1.value })?.key ?? .blue
            
            // Most used icon
            let iconCounts = Dictionary(grouping: folders, by: { $0.icon })
                .mapValues { $0.count }
            mostUsedIcon = iconCounts.max(by: { $0.value < $1.value })?.key ?? .folder
        }
    }
    
    static func statistics(for folders: [Folder]) -> Statistics {
        return Statistics(from: folders)
    }
}
