const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Security configuration
const AUTHORIZED_IP = process.env.USER_IP || '127.0.0.1';
const SECRET_KEY = process.env.SECRET_KEY || crypto.randomBytes(32).toString('hex');

app.use(express.json());
app.use(express.static('public'));

// Security middleware - only allow requests from authorized IP
app.use((req, res, next) => {
    const clientIP = req.ip || req.connection.remoteAddress;
    
    if (clientIP !== AUTHORIZED_IP && !clientIP.includes('127.0.0.1')) {
        console.log(`🚫 Unauthorized access attempt from: ${clientIP}`);
        return res.status(403).json({ 
            error: 'Access denied',
            message: 'This service is only available from authorized devices'
        });
    }
    
    console.log(`✅ Authorized access from: ${clientIP}`);
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        authorized: true
    });
});

// Start workflow endpoint
app.post('/start-workflow', async (req, res) => {
    try {
        const { workflow, event = 'push' } = req.body;
        
        console.log(`🚀 Starting workflow: ${workflow} with event: ${event}`);
        
        // Execute workflow using act
        const command = `act -W .github/workflows/${workflow} ${event}`;
        
        exec(command, { cwd: '/workspace' }, (error, stdout, stderr) => {
            if (error) {
                console.error(`❌ Workflow failed: ${error.message}`);
                return res.status(500).json({ 
                    error: 'Workflow execution failed',
                    details: error.message
                });
            }
            
            console.log(`✅ Workflow completed successfully`);
            console.log(`📋 Output: ${stdout}`);
            
            res.json({ 
                success: true,
                message: 'Workflow executed successfully',
                output: stdout,
                timestamp: new Date().toISOString()
            });
        });
        
    } catch (error) {
        console.error(`❌ Error starting workflow: ${error.message}`);
        res.status(500).json({ 
            error: 'Failed to start workflow',
            details: error.message
        });
    }
});

// List available workflows
app.get('/workflows', (req, res) => {
    const workflowsDir = path.join('/workspace', '.github', 'workflows');
    
    try {
        if (!fs.existsSync(workflowsDir)) {
            return res.json({ workflows: [] });
        }
        
        const files = fs.readdirSync(workflowsDir);
        const workflows = files
            .filter(file => file.endsWith('.yml') || file.endsWith('.yaml'))
            .map(file => ({
                name: file,
                path: `.github/workflows/${file}`
            }));
        
        res.json({ workflows });
        
    } catch (error) {
        console.error(`❌ Error reading workflows: ${error.message}`);
        res.status(500).json({ 
            error: 'Failed to read workflows',
            details: error.message
        });
    }
});

// Status endpoint
app.get('/status', (req, res) => {
    res.json({
        status: 'running',
        authorized_ip: AUTHORIZED_IP,
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.listen(PORT, () => {
    console.log(`🚀 LocalWorkflowRunner started on port ${PORT}`);
    console.log(`🔒 Authorized IP: ${AUTHORIZED_IP}`);
    console.log(`📁 Working directory: /workspace`);
    console.log(`⏰ Started at: ${new Date().toISOString()}`);
});
