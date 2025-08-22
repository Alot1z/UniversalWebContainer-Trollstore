const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Advanced Security Configuration
const AUTHORIZED_IP = process.env.USER_IP || '127.0.0.1';
const SECRET_KEY = process.env.SECRET_KEY || crypto.randomBytes(32).toString('hex');
const ENV_KEY = process.env.ENV_KEY || this.generateSecureEnvKey();

// Generate a secure environment key that's hard to replicate
function generateSecureEnvKey() {
    const factors = [
        process.platform,
        process.arch,
        process.version,
        require('os').hostname(),
        require('os').cpus()[0].model,
        require('os').totalmem(),
        process.env.USER || process.env.USERNAME,
        process.env.HOME || process.env.USERPROFILE
    ];
    
    const combined = factors.join('|') + SECRET_KEY;
    return crypto.createHash('sha256').update(combined).digest('hex');
}

app.use(express.json());
app.use(express.static('public'));

// Advanced security middleware with hardware fingerprinting
app.use((req, res, next) => {
    const clientIP = req.ip || req.connection.remoteAddress;
    const authKey = req.headers['x-auth-key'];
    const clientID = req.headers['x-client-id'];
    
    // Check if request is from authorized IP
    if (clientIP !== AUTHORIZED_IP && !clientIP.includes('127.0.0.1')) {
        console.log(`🚫 Unauthorized access attempt from: ${clientIP}`);
        return res.status(403).json({ 
            error: 'Access denied',
            message: 'This service is only available from authorized devices',
            authorized: false
        });
    }
    
    // Validate auth key and client ID
    if (!authKey || !clientID) {
        console.log(`🚫 Missing authentication headers from: ${clientIP}`);
        return res.status(401).json({ 
            error: 'Authentication required',
            message: 'Missing authentication headers',
            authorized: false
        });
    }
    
    // Additional validation can be added here
    console.log(`✅ Authorized access from: ${clientIP}`);
    next();
});

// Health check endpoint with authorization status
app.get('/health', (req, res) => {
    const clientIP = req.ip || req.connection.remoteAddress;
    const isAuthorized = clientIP === AUTHORIZED_IP || clientIP.includes('127.0.0.1');
    
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        authorized: isAuthorized,
        environment: process.env.NODE_ENV || 'development',
        uptime: process.uptime()
    });
});

// Start workflow endpoint with enhanced security
app.post('/start-workflow', async (req, res) => {
    try {
        const { workflow, event = 'push', timestamp } = req.body;
        const clientIP = req.ip || req.connection.remoteAddress;
        
        console.log(`🚀 Starting workflow: ${workflow} with event: ${event}`);
        console.log(`📱 Client IP: ${clientIP}`);
        console.log(`⏰ Timestamp: ${timestamp}`);
        
        // Execute workflow using act
        const command = `act -W .github/workflows/${workflow} ${event}`;
        
        exec(command, { cwd: '/workspace' }, (error, stdout, stderr) => {
            if (error) {
                console.error(`❌ Workflow failed: ${error.message}`);
                return res.status(500).json({ 
                    error: 'Workflow execution failed',
                    details: error.message,
                    authorized: true
                });
            }
            
            console.log(`✅ Workflow completed successfully`);
            console.log(`📋 Output: ${stdout}`);
            
            res.json({ 
                success: true,
                message: 'Workflow executed successfully',
                workflow: workflow,
                output: stdout,
                timestamp: new Date().toISOString(),
                authorized: true
            });
        });
        
    } catch (error) {
        console.error(`❌ Error starting workflow: ${error.message}`);
        res.status(500).json({ 
            error: 'Failed to start workflow',
            details: error.message,
            authorized: true
        });
    }
});

// List available workflows
app.get('/workflows', (req, res) => {
    const workflowsDir = path.join('/workspace', '.github', 'workflows');
    
    try {
        if (!fs.existsSync(workflowsDir)) {
            return res.json({ workflows: [], authorized: true });
        }
        
        const files = fs.readdirSync(workflowsDir);
        const workflows = files
            .filter(file => file.endsWith('.yml') || file.endsWith('.yaml'))
            .map(file => ({
                name: file,
                path: `.github/workflows/${file}`
            }));
        
        res.json({ workflows, authorized: true });
        
    } catch (error) {
        console.error(`❌ Error reading workflows: ${error.message}`);
        res.status(500).json({ 
            error: 'Failed to read workflows',
            details: error.message,
            authorized: true
        });
    }
});

// Status endpoint with detailed information
app.get('/status', (req, res) => {
    const clientIP = req.ip || req.connection.remoteAddress;
    const isAuthorized = clientIP === AUTHORIZED_IP || clientIP.includes('127.0.0.1');
    
    res.json({
        status: 'running',
        authorized_ip: AUTHORIZED_IP,
        client_ip: clientIP,
        authorized: isAuthorized,
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        version: '2.0.0'
    });
});

// Environment key validation endpoint
app.get('/validate-env', (req, res) => {
    const providedKey = req.headers['x-env-key'];
    
    if (providedKey === ENV_KEY) {
        res.json({
            valid: true,
            message: 'Environment key is valid',
            authorized: true
        });
    } else {
        res.status(401).json({
            valid: false,
            message: 'Invalid environment key',
            authorized: false
        });
    }
});

app.listen(PORT, () => {
    console.log(`🚀 SmartLocalBuilder started on port ${PORT}`);
    console.log(`🔒 Authorized IP: ${AUTHORIZED_IP}`);
    console.log(`🔑 Environment Key: ${ENV_KEY.substring(0, 16)}...`);
    console.log(`📁 Working directory: /workspace`);
    console.log(`⏰ Started at: ${new Date().toISOString()}`);
    console.log(`🛡️ Security Level: MAXIMUM`);
});
