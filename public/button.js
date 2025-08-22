// Smart Button for LocalWorkflowRunner
// Only works from authorized computers

class LocalBuilderButton {
    constructor() {
        this.apiUrl = 'http://localhost:3000';
        this.isAuthorized = false;
        this.init();
    }

    async init() {
        try {
            // Check if local runner is available
            const response = await fetch(`${this.apiUrl}/health`);
            if (response.ok) {
                this.isAuthorized = true;
                this.updateButtonStatus('ready');
            } else {
                this.updateButtonStatus('offline');
            }
        } catch (error) {
            this.updateButtonStatus('offline');
        }
    }

    updateButtonStatus(status) {
        const button = document.getElementById('local-builder-btn');
        if (!button) return;

        switch (status) {
            case 'ready':
                button.innerHTML = '🚀 Start Local Builder';
                button.className = 'btn btn-success';
                button.onclick = () => this.startWorkflow();
                break;
            case 'running':
                button.innerHTML = '⏳ Running...';
                button.className = 'btn btn-warning';
                button.disabled = true;
                break;
            case 'offline':
                button.innerHTML = '🔌 Offline';
                button.className = 'btn btn-secondary';
                button.disabled = true;
                break;
            case 'error':
                button.innerHTML = '❌ Error';
                button.className = 'btn btn-danger';
                button.disabled = true;
                break;
        }
    }

    async startWorkflow() {
        if (!this.isAuthorized) {
            alert('❌ LocalWorkflowRunner is not available from this device.');
            return;
        }

        this.updateButtonStatus('running');

        try {
            const response = await fetch(`${this.apiUrl}/start-workflow`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    workflow: 'build.yml',
                    event: 'push'
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
            this.showError({ error: 'Network error', details: error.message });
        }

        this.updateButtonStatus('ready');
    }

    showSuccess(result) {
        const modal = this.createModal('✅ Workflow Started', `
            <div class="alert alert-success">
                <h4>🎉 Workflow executed successfully!</h4>
                <p><strong>Output:</strong></p>
                <pre>${result.output || 'No output'}</pre>
                <p><strong>Timestamp:</strong> ${result.timestamp}</p>
            </div>
        `);
        document.body.appendChild(modal);
    }

    showError(error) {
        const modal = this.createModal('❌ Workflow Failed', `
            <div class="alert alert-danger">
                <h4>Error executing workflow</h4>
                <p><strong>Error:</strong> ${error.error}</p>
                <p><strong>Details:</strong> ${error.details || 'No details'}</p>
            </div>
        `);
        document.body.appendChild(modal);
    }

    createModal(title, content) {
        const modal = document.createElement('div');
        modal.className = 'modal fade show';
        modal.style.display = 'block';
        modal.innerHTML = `
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">${title}</h5>
                        <button type="button" class="btn-close" onclick="this.closest('.modal').remove()"></button>
                    </div>
                    <div class="modal-body">
                        ${content}
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.modal').remove()">Close</button>
                    </div>
                </div>
            </div>
        `;
        return modal;
    }
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    new LocalBuilderButton();
});

// Add CSS for modal
const style = document.createElement('style');
style.textContent = `
    .modal {
        background-color: rgba(0,0,0,0.5);
    }
    .btn {
        padding: 10px 20px;
        border: none;
        border-radius: 5px;
        cursor: pointer;
        font-weight: bold;
        text-decoration: none;
        display: inline-block;
        margin: 5px;
    }
    .btn-success { background-color: #28a745; color: white; }
    .btn-warning { background-color: #ffc107; color: black; }
    .btn-secondary { background-color: #6c757d; color: white; }
    .btn-danger { background-color: #dc3545; color: white; }
    .btn:disabled { opacity: 0.6; cursor: not-allowed; }
    .alert { padding: 15px; margin: 10px 0; border-radius: 5px; }
    .alert-success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
    .alert-danger { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
    pre { background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
`;
document.head.appendChild(style);
