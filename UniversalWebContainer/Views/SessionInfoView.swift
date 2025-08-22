import SwiftUI

// MARK: - Session Info View
struct SessionInfoView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var keychainManager: KeychainManager
    @Environment(\.dismiss) private var dismiss
    
    let webApp: WebApp
    @State private var sessionInfo: WebAppSession?
    @State private var isRefreshing = false
    @State private var showingClearSessionAlert = false
    @State private var showingExportSessionAlert = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                // Header Section
                headerSection
                
                // Session Status
                sessionStatusSection
                
                // Session Details
                if let sessionInfo = sessionInfo {
                    sessionDetailsSection(sessionInfo)
                }
                
                // Security Info
                securitySection
                
                // Actions
                actionsSection
            }
            .navigationTitle("Session Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Clear Session", isPresented: $showingClearSessionAlert) {
            Button("Clear", role: .destructive) {
                clearSession()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all session data for '\(webApp.name)'. You will need to log in again.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadSessionInfo()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                // WebApp Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 50)
                    
                    if let iconData = webApp.icon.data,
                       let uiImage = UIImage(data: iconData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .cornerRadius(6)
                    } else {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                // WebApp Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(webApp.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(webApp.domain)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Session Status Section
    private var sessionStatusSection: some View {
        Section("Session Status") {
            HStack {
                Image(systemName: sessionInfo != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(sessionInfo != nil ? .green : .red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Session Status")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(sessionInfo != nil ? "Active" : "No Active Session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Refresh") {
                        refreshSessionInfo()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if sessionInfo != nil {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Security Status")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("Session data is encrypted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Session Details Section
    private func sessionDetailsSection(_ session: WebAppSession) -> some View {
        Section("Session Details") {
            HStack {
                Text("Session ID")
                    .font(.body)
                
                Spacer()
                
                Text(session.sessionId.prefix(8) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Created")
                    .font(.body)
                
                Spacer()
                
                Text(session.createdDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Last Active")
                    .font(.body)
                
                Spacer()
                
                Text(session.lastActiveDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Expires")
                    .font(.body)
                
                Spacer()
                
                if let expiryDate = session.expiryDate {
                    Text(expiryDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("User Agent")
                    .font(.body)
                
                Spacer()
                
                Text(session.userAgent.prefix(20) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        Section("Security") {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keychain Storage")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Session data stored securely")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                Image(systemName: "lock.rotation")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Encryption")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("AES-256 encryption")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Access Control")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Device-only access")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        Section("Actions") {
            Button(action: { showingClearSessionAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Clear Session")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            .disabled(sessionInfo == nil)
            
            Button(action: exportSession) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Export Session")
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            .disabled(sessionInfo == nil)
            
            Button(action: refreshSessionInfo) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("Refresh Session")
                        .foregroundColor(.green)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadSessionInfo() {
        Task {
            do {
                let session = try await sessionManager.getSessionInfo(for: webApp)
                
                await MainActor.run {
                    sessionInfo = session
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func refreshSessionInfo() {
        isRefreshing = true
        
        Task {
            do {
                let session = try await sessionManager.refreshSession(for: webApp)
                
                await MainActor.run {
                    sessionInfo = session
                    isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRefreshing = false
                }
            }
        }
    }
    
    private func clearSession() {
        Task {
            do {
                try await sessionManager.clearSession(for: webApp)
                
                await MainActor.run {
                    sessionInfo = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func exportSession() {
        Task {
            do {
                let sessionData = try await sessionManager.exportSession(for: webApp)
                
                await MainActor.run {
                    // Share session data
                    let activityVC = UIActivityViewController(
                        activityItems: [sessionData],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview
struct SessionInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SessionInfoView(webApp: WebApp.sample)
            .environmentObject(SessionManager())
            .environmentObject(KeychainManager())
    }
}
