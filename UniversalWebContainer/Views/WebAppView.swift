import SwiftUI
import WebKit

// MARK: - WebApp View
struct WebAppView: View {
    let webApp: WebApp
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var capabilityService: CapabilityService
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var offlineManager: OfflineManager
    
    @State private var webView: WKWebView?
    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var currentURL: URL?
    @State private var showSettings = false
    @State private var showShareSheet = false
    @State private var showSessionInfo = false
    @State private var errorMessage: String?
    @State private var isDesktopMode = false
    @State private var isOfflineMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            navigationBar
            
            // WebView
            webViewContainer
            
            // Bottom Toolbar
            bottomToolbar
        }
        .navigationBarHidden(true)
        .onAppear {
            setupWebView()
            loadWebApp()
        }
        .sheet(isPresented: $showSettings) {
            WebAppSettingsView(webApp: webApp)
        }
        .sheet(isPresented: $showSessionInfo) {
            SessionInfoView(webApp: webApp)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [currentURL?.absoluteString ?? ""])
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Back Button
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(canGoBack ? .primary : .secondary)
            }
            .disabled(!canGoBack)
            
            // Forward Button
            Button(action: goForward) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(canGoForward ? .primary : .secondary)
            }
            .disabled(!canGoForward)
            
            // URL Display
            VStack(alignment: .leading, spacing: 2) {
                Text(webApp.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if let url = currentURL {
                    Text(url.host ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Session Status
            sessionStatusIndicator
            
            // Settings Button
            Button(action: { showSettings = true }) {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - WebView Container
    private var webViewContainer: some View {
        ZStack {
            if let webView = webView {
                WebViewRepresentable(
                    webView: webView,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    currentURL: $currentURL,
                    errorMessage: $errorMessage
                )
            } else {
                ProgressView("Loading...")
            }
            
            // Loading Overlay
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.8))
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Refresh Button
            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
            }
            
            // Desktop Mode Toggle
            if capabilityService.canUseFeature(.alternativeEngine) {
                Button(action: toggleDesktopMode) {
                    Image(systemName: isDesktopMode ? "laptopcomputer" : "iphone")
                        .font(.title2)
                        .foregroundColor(isDesktopMode ? .blue : .primary)
                }
            }
            
            // Offline Mode Toggle
            if offlineManager.isOfflineContentAvailable(for: webApp) {
                Button(action: toggleOfflineMode) {
                    Image(systemName: isOfflineMode ? "wifi.slash" : "wifi")
                        .font(.title2)
                        .foregroundColor(isOfflineMode ? .orange : .primary)
                }
            }
            
            Spacer()
            
            // Share Button
            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
            }
            
            // Session Info Button
            Button(action: { showSessionInfo = true }) {
                Image(systemName: "info.circle")
                    .font(.title2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
    
    // MARK: - Session Status Indicator
    private var sessionStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(sessionManager.hasActiveSession(for: webApp) ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(sessionManager.hasActiveSession(for: webApp) ? "✓" : "🔒")
                .font(.caption)
                .foregroundColor(sessionManager.hasActiveSession(for: webApp) ? .green : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Methods
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Configure based on container type
        switch webApp.containerType {
        case .private:
            configuration.websiteDataStore = .nonPersistent()
        case .standard, .multiAccount:
            // Use persistent data store with session isolation
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }
        
        // Set desktop mode if enabled
        if webApp.settings.isDesktopMode {
            configuration.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
        }
        
        // Configure content blocking
        if webApp.settings.isAdBlockEnabled {
            // Add content blocking rules
            let contentRuleList = WKContentRuleList()
            // Implementation would add actual ad blocking rules
        }
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = WebViewNavigationDelegate(
            sessionManager: sessionManager,
            webApp: webApp
        )
    }
    
    private func loadWebApp() {
        guard let webView = webView else { return }
        
        // Check for offline content first
        if isOfflineMode, let offlineURL = offlineManager.getOfflineURL(for: webApp) {
            webView.loadFileURL(offlineURL, allowingReadAccessTo: offlineURL.deletingLastPathComponent())
        } else {
            // Load from network
            let request = URLRequest(url: webApp.url)
            webView.load(request)
        }
    }
    
    private func goBack() {
        webView?.goBack()
    }
    
    private func goForward() {
        webView?.goForward()
    }
    
    private func refresh() {
        webView?.reload()
    }
    
    private func toggleDesktopMode() {
        isDesktopMode.toggle()
        // Update web app settings
        var updatedWebApp = webApp
        updatedWebApp.settings.isDesktopMode = isDesktopMode
        // Save updated settings
    }
    
    private func toggleOfflineMode() {
        isOfflineMode.toggle()
        if isOfflineMode {
            loadWebApp()
        }
    }
}

// MARK: - WebView Representable
struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var currentURL: URL?
    @Binding var errorMessage: String?
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Updates handled by coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable
        
        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.errorMessage = nil
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            parent.currentURL = webView.url
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.errorMessage = error.localizedDescription
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - WebView Navigation Delegate
class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    let sessionManager: SessionManager
    let webApp: WebApp
    
    init(sessionManager: SessionManager, webApp: WebApp) {
        self.sessionManager = sessionManager
        self.webApp = webApp
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Save session data
        sessionManager.saveSession(for: webApp, webView: webView)
        
        // Update web app metadata
        var updatedWebApp = webApp
        updatedWebApp.metadata.lastAccessed = Date()
        updatedWebApp.metadata.accessCount += 1
        // Save updated metadata
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - WebApp Settings View
struct WebAppSettingsView: View {
    let webApp: WebApp
    
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var capabilityService: CapabilityService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isDesktopMode: Bool
    @State private var isAdBlockEnabled: Bool
    @State private var isJavaScriptEnabled: Bool
    @State private var customUserAgent: String
    @State private var showingClearDataAlert = false
    @State private var showingExportData = false
    
    init(webApp: WebApp) {
        self.webApp = webApp
        self._isDesktopMode = State(initialValue: webApp.settings.isDesktopMode)
        self._isAdBlockEnabled = State(initialValue: webApp.settings.isAdBlockEnabled)
        self._isJavaScriptEnabled = State(initialValue: webApp.settings.javaScriptEnabled)
        self._customUserAgent = State(initialValue: webApp.settings.customUserAgent ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display")) {
                    Toggle("Desktop Mode", isOn: $isDesktopMode)
                        .disabled(!capabilityService.canUseFeature(.alternativeEngine))
                    
                    if !capabilityService.canUseFeature(.alternativeEngine) {
                        Text("Desktop mode requires iOS 13+")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Content")) {
                    Toggle("Ad Block", isOn: $isAdBlockEnabled)
                        .disabled(!capabilityService.canUseFeature(.contentBlocking))
                    
                    Toggle("JavaScript", isOn: $isJavaScriptEnabled)
                    
                    TextField("Custom User Agent", text: $customUserAgent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Session")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(sessionStatusText)
                            .foregroundColor(sessionStatusColor)
                    }
                    
                    Button("Clear Site Data") {
                        showingClearDataAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Data")) {
                    Button("Export Data") {
                        showingExportData = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSettings()
                }
            )
        }
        .alert("Clear Site Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearSiteData()
            }
        } message: {
            Text("This will clear all cookies, cache, and local storage for this web app.")
        }
    }
    
    private var sessionStatusText: String {
        let status = sessionManager.getAuthenticationStatus(for: webApp)
        switch status {
        case .authenticatedWithTokens:
            return "Authenticated (Tokens)"
        case .authenticatedWithCookies:
            return "Authenticated (Cookies)"
        case .notAuthenticated:
            return "Not Authenticated"
        case .expired:
            return "Session Expired"
        case .inactive:
            return "Session Inactive"
        }
    }
    
    private var sessionStatusColor: Color {
        let status = sessionManager.getAuthenticationStatus(for: webApp)
        switch status {
        case .authenticatedWithTokens, .authenticatedWithCookies:
            return .green
        case .notAuthenticated:
            return .red
        case .expired:
            return .orange
        case .inactive:
            return .gray
        }
    }
    
    private func saveSettings() {
        // Update webApp settings
        // This would need to be implemented in WebAppManager
        presentationMode.wrappedValue.dismiss()
    }
    
    private func clearSiteData() {
        Task {
            await sessionManager.clearSessionData(for: webApp)
        }
    }
}

// MARK: - Session Info View
struct SessionInfoView: View {
    let webApp: WebApp
    
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if let session = sessionManager.getSession(for: webApp) {
                    Section(header: Text("Session Information")) {
                        HStack {
                            Text("Type")
                            Spacer()
                            Text(session.sessionType.displayName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(session.status.displayName)
                                .foregroundColor(session.status.color)
                        }
                        
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(session.createdAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Activity")
                            Spacer()
                            Text(session.lastActivity, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("Data")) {
                        HStack {
                            Text("Cookies")
                            Spacer()
                            Text("\(session.cookies.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Local Storage")
                            Spacer()
                            Text("\(session.localStorage.count) items")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Session Storage")
                            Spacer()
                            Text("\(session.sessionStorage.count) items")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Tokens")
                            Spacer()
                            Text("\(session.tokens.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Section {
                        Text("No active session")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Session Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Preview
struct WebAppView_Previews: PreviewProvider {
    static var previews: some View {
        WebAppView(webApp: WebApp.sampleWebApps[0])
            .environmentObject(SessionManager())
            .environmentObject(NotificationManager())
            .environmentObject(CapabilityService())
            .environmentObject(OfflineManager())
    }
}
