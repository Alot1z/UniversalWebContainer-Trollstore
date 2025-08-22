import SwiftUI

// MARK: - Folder Picker View
struct FolderPickerView: View {
    @EnvironmentObject var webAppManager: WebAppManager
    @Environment(\.dismiss) private var dismiss
    
    let onFolderSelected: (Folder?) -> Void
    
    @State private var searchText = ""
    @State private var showingCreateFolder = false
    @State private var selectedFolder: Folder?
    @State private var newFolderName = ""
    @State private var newFolderColor: FolderColor = .blue
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search Bar
                searchSection
                
                // Folder List
                folderListSection
                
                // Action Buttons
                actionButtonsSection
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Folder") {
                        showingCreateFolder = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateFolder) {
            CreateFolderView(
                folderName: $newFolderName,
                folderColor: $newFolderColor,
                onSave: createNewFolder
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Select a Folder")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a folder to organize your webapp, or create a new one")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search folders...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Folder List Section
    private var folderListSection: some View {
        List {
            // No Folder Option
            Section {
                Button(action: { selectedFolder = nil }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Folder")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("Keep webapp in main list")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedFolder == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Folders
            Section("Folders") {
                ForEach(filteredFolders) { folder in
                    FolderRow(
                        folder: folder,
                        isSelected: selectedFolder?.id == folder.id,
                        webAppCount: webAppManager.getWebApps(in: folder).count
                    ) {
                        selectedFolder = folder
                    }
                }
            }
            
            if filteredFolders.isEmpty && !searchText.isEmpty {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        Text("No folders found")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Select Folder") {
                onFolderSelected(selectedFolder)
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(selectedFolder == nil && webAppManager.folders.isEmpty)
            
            if selectedFolder != nil {
                Button("Remove from Folder") {
                    onFolderSelected(nil)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    private var filteredFolders: [Folder] {
        if searchText.isEmpty {
            return webAppManager.folders
        } else {
            return webAppManager.folders.filter { folder in
                folder.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func createNewFolder() {
        guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let folder = Folder(
            name: newFolderName.trimmingCharacters(in: .whitespacesAndNewlines),
            color: newFolderColor,
            icon: "folder",
            sortOrder: .name,
            isAscending: true
        )
        
        webAppManager.addFolder(folder)
        selectedFolder = folder
        
        // Reset form
        newFolderName = ""
        newFolderColor = .blue
        showingCreateFolder = false
    }
}

// MARK: - Folder Row
struct FolderRow: View {
    let folder: Folder
    let isSelected: Bool
    let webAppCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Folder Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(folder.color.color)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: folder.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                // Folder Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(webAppCount) webapp\(webAppCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Folder View
struct CreateFolderView: View {
    @Binding var folderName: String
    @Binding var folderColor: FolderColor
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let colors: [FolderColor] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow, .gray
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Folder Color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                ColorSelectionButton(
                                    color: color,
                                    isSelected: folderColor == color
                                ) {
                                    folderColor = color
                                }
                            }
                        }
                    }
                }
                
                Section("Preview") {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(folderColor.color)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "folder")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(folderName.isEmpty ? "Folder Name" : folderName)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("0 webapps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Create Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onSave()
                    }
                    .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Color Selection Button
struct ColorSelectionButton: View {
    let color: FolderColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 40, height: 40)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Folder Color Extension
extension FolderColor {
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
}

// MARK: - Preview
struct FolderPickerView_Previews: PreviewProvider {
    static var previews: some View {
        FolderPickerView { folder in
            print("Selected folder: \(folder?.name ?? "None")")
        }
        .environmentObject(WebAppManager())
    }
}
