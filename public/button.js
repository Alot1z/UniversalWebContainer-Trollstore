// Smart LocalBuilder Button with Advanced Security
// Only works from authorized computers with proper authentication

class SmartLocalBuilder {
    constructor() {
        this.apiUrl = 'http://localhost:3000';
        this.isAuthorized = false;
        this.isRunning = false;
        this.authKey = this.generateAuthKey();
        this.init();
    }

    generateAuthKey() {
        // Generate a unique auth key based on hardware fingerprint
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        ctx.textBaseline = 'top';
        ctx.font = '14px Arial';
        ctx.fillText('SmartLocalBuilder', 2, 2);
        
        const fingerprint = canvas.toDataURL();
        const timestamp = new Date().getTime();
        const userAgent = navigator.userAgent;
        
        // Create a unique key that's hard to replicate
        return btoa(fingerprint + timestamp + userAgent + window.screen.width + window.screen.height);
    }

    async init() {
        try {
            // Check if local runner is available
            const response = await fetch(`${this.apiUrl}/health`, {
                method: 'GET',
                headers: {
                    'X-Auth-Key': this.authKey,
                    'X-Client-ID': this.getClientID()
                }
            });
            
            if (response.ok) {
                const data = await response.json();
                if (data.authorized) {
                    this.isAuthorized = true;
                    this.updateButtonStatus('ready');
                    this.updateStatusBadge('authorized');
                } else {
                    this.updateButtonStatus('unauthorized');
                    this.updateStatusBadge('unauthorized');
                }
            } else {
                this.updateButtonStatus('offline');
                this.updateStatusBadge('offline');
            }
        } catch (error) {
            this.updateButtonStatus('offline');
            this.updateStatusBadge('offline');
        }
    }

    getClientID() {
        // Create a unique client ID based on multiple factors
        const factors = [
            navigator.userAgent,
            navigator.language,
            new Date().getTimezoneOffset(),
            window.screen.width,
            window.screen.height,
            window.screen.colorDepth,
            navigator.hardwareConcurrency,
            navigator.deviceMemory || 'unknown'
        ];
        
        return btoa(factors.join('|'));
    }

    updateButtonStatus(status) {
        const button = document.getElementById('local-builder-btn');
        const statusBadge = document.getElementById('status-badge');
        
        if (!button) return;

        switch (status) {
            case 'ready':
                button.innerHTML = '🚀 START LOCAL BUILDER';
                button.className = 'smart-btn smart-btn-success';
                button.onclick = () => this.startWorkflow();
                button.disabled = false;
                break;
            case 'running':
                button.innerHTML = '⏳ BUILDING...';
                button.className = 'smart-btn smart-btn-warning';
                button.disabled = true;
                break;
            case 'unauthorized':
                button.innerHTML = '🔒 UNAUTHORIZED';
                button.className = 'smart-btn smart-btn-danger';
                button.onclick = () => this.showUnauthorizedMessage();
                button.disabled = false;
                break;
            case 'offline':
                button.innerHTML = '🔌 OFFLINE';
                button.className = 'smart-btn smart-btn-secondary';
                button.disabled = true;
                break;
            case 'error':
                button.innerHTML = '❌ ERROR';
                button.className = 'smart-btn smart-btn-danger';
                button.disabled = true;
                break;
        }
    }

    updateStatusBadge(status) {
        const statusBadge = document.getElementById('status-badge');
        if (!statusBadge) return;

        switch (status) {
            case 'authorized':
                statusBadge.innerHTML = '<span class="status-icon">🔒</span> AUTHORIZED';
                statusBadge.className = 'status-badge status-authorized';
                break;
            case 'unauthorized':
                statusBadge.innerHTML = '<span class="status-icon">🚫</span> UNAUTHORIZED';
                statusBadge.className = 'status-badge status-unauthorized';
                break;
            case 'offline':
                statusBadge.innerHTML = '<span class="status-icon">🔌</span> OFFLINE';
                statusBadge.className = 'status-badge status-offline';
                break;
            case 'running':
                statusBadge.innerHTML = '<span class="status-icon">⚡</span> RUNNING';
                statusBadge.className = 'status-badge status-running';
                break;
        }
    }

    showUnauthorizedMessage() {
        const modal = this.createModal('🚫 Access Denied', `
            <div class="alert alert-danger">
                <h4>❌ Unauthorized Access</h4>
                <p><strong>This LocalBuilder is only available from authorized devices.</strong></p>
                <p>If you're the repository owner, please:</p>
                <ul>
                    <li>Ensure you're accessing from your authorized computer</li>
                    <li>Check that the local builder service is running</li>
                    <li>Verify your network connection</li>
                </ul>
                <p><em>For security reasons, this service cannot be accessed from unauthorized devices.</em></p>
            </div>
        `);
        document.body.appendChild(modal);
    }

    async startWorkflow() {
        if (!this.isAuthorized) {
            this.showUnauthorizedMessage();
            return;
        }

        this.updateButtonStatus('running');
        this.updateStatusBadge('running');

        try {
            const response = await fetch(`${this.apiUrl}/start-workflow`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Auth-Key': this.authKey,
                    'X-Client-ID': this.getClientID()
                },
                body: JSON.stringify({
                    workflow: 'build.yml',
                    event: 'push',
                    timestamp: new Date().toISOString()
                })
            });

            if (response.ok) {
                const result = await response.json();
                this.showSuccess(result);
            } else {
                const error = await response.json();
                this.showError(error);
            }
        } catch (error) {
            this.showError({ 
                error: 'Network error', 
                details: 'Cannot connect to local builder service. Please ensure the service is running.' 
            });
        }

        this.updateButtonStatus('ready');
        this.updateStatusBadge('authorized');
    }

    showSuccess(result) {
        const modal = this.createModal('✅ Build Started Successfully', `
            <div class="alert alert-success">
                <h4>🎉 Local Build Initiated!</h4>
                <p><strong>Workflow:</strong> ${result.workflow || 'build.yml'}</p>
                <p><strong>Status:</strong> Running locally</p>
                <p><strong>Timestamp:</strong> ${result.timestamp}</p>
                <hr>
                <p><strong>What's happening:</strong></p>
                <ul>
                    <li>✅ Local builder service activated</li>
                    <li>⚡ GitHub Actions workflow running locally</li>
                    <li>🔧 No GitHub credits consumed</li>
                    <li>🚀 Faster than cloud builds</li>
                </ul>
                <p><em>Check your local terminal for build progress...</em></p>
            </div>
        `);
        document.body.appendChild(modal);
    }

    showError(error) {
        const modal = this.createModal('❌ Build Failed', `
            <div class="alert alert-danger">
                <h4>Error Starting Local Build</h4>
                <p><strong>Error:</strong> ${error.error}</p>
                <p><strong>Details:</strong> ${error.details || 'No details available'}</p>
                <hr>
                <p><strong>Troubleshooting:</strong></p>
                <ul>
                    <li>Ensure Docker is running</li>
                    <li>Check if local builder service is started</li>
                    <li>Verify network connectivity</li>
                    <li>Check Docker logs for errors</li>
                </ul>
            </div>
        `);
        document.body.appendChild(modal);
    }

    createModal(title, content) {
        const modal = document.createElement('div');
        modal.className = 'smart-modal fade show';
        modal.style.display = 'block';
        modal.innerHTML = `
            <div class="smart-modal-dialog">
                <div class="smart-modal-content">
                    <div class="smart-modal-header">
                        <h5 class="smart-modal-title">${title}</h5>
                        <button type="button" class="smart-modal-close" onclick="this.closest('.smart-modal').remove()">×</button>
                    </div>
                    <div class="smart-modal-body">
                        ${content}
                    </div>
                    <div class="smart-modal-footer">
                        <button type="button" class="smart-btn smart-btn-secondary" onclick="this.closest('.smart-modal').remove()">Close</button>
                    </div>
                </div>
            </div>
        `;
        return modal;
    }
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    new SmartLocalBuilder();
});

// Add advanced CSS for smart button
const smartStyle = document.createElement('style');
smartStyle.textContent = `
    .smart-btn {
        padding: 12px 24px;
        border: none;
        border-radius: 8px;
        cursor: pointer;
        font-weight: bold;
        font-size: 14px;
        text-decoration: none;
        display: inline-block;
        margin: 5px;
        transition: all 0.3s ease;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .smart-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    }
    
    .smart-btn-success { 
        background: linear-gradient(135deg, #28a745, #20c997);
        color: white;
    }
    
    .smart-btn-warning { 
        background: linear-gradient(135deg, #ffc107, #fd7e14);
        color: white;
    }
    
    .smart-btn-danger { 
        background: linear-gradient(135deg, #dc3545, #e83e8c);
        color: white;
    }
    
    .smart-btn-secondary { 
        background: linear-gradient(135deg, #6c757d, #495057);
        color: white;
    }
    
    .smart-btn:disabled { 
        opacity: 0.6; 
        cursor: not-allowed;
        transform: none;
    }
    
    .status-badge {
        padding: 8px 16px;
        border-radius: 20px;
        font-weight: bold;
        font-size: 12px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .status-authorized {
        background: linear-gradient(135deg, #007bff, #0056b3);
        color: white;
    }
    
    .status-unauthorized {
        background: linear-gradient(135deg, #dc3545, #c82333);
        color: white;
    }
    
    .status-offline {
        background: linear-gradient(135deg, #6c757d, #545b62);
        color: white;
    }
    
    .status-running {
        background: linear-gradient(135deg, #28a745, #1e7e34);
        color: white;
        animation: pulse 2s infinite;
    }
    
    @keyframes pulse {
        0% { opacity: 1; }
        50% { opacity: 0.7; }
        100% { opacity: 1; }
    }
    
    .smart-modal {
        background-color: rgba(0,0,0,0.7);
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    
    .smart-modal-dialog {
        background: white;
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        max-width: 500px;
        width: 90%;
        max-height: 80vh;
        overflow-y: auto;
    }
    
    .smart-modal-header {
        padding: 20px 24px 0;
        border-bottom: 1px solid #e9ecef;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    
    .smart-modal-title {
        margin: 0;
        font-size: 18px;
        font-weight: bold;
    }
    
    .smart-modal-close {
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        color: #6c757d;
        padding: 0;
        width: 30px;
        height: 30px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        transition: background-color 0.3s;
    }
    
    .smart-modal-close:hover {
        background-color: #f8f9fa;
    }
    
    .smart-modal-body {
        padding: 24px;
    }
    
    .smart-modal-footer {
        padding: 0 24px 20px;
        text-align: right;
    }
    
    .alert {
        padding: 16px;
        margin: 16px 0;
        border-radius: 8px;
        border-left: 4px solid;
    }
    
    .alert-success {
        background-color: #d4edda;
        border-color: #28a745;
        color: #155724;
    }
    
    .alert-danger {
        background-color: #f8d7da;
        border-color: #dc3545;
        color: #721c24;
    }
    
    .status-icon {
        font-size: 14px;
    }
`;
document.head.appendChild(smartStyle);
