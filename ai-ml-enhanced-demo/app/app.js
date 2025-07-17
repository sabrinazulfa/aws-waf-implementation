const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const crypto = require('crypto');
const rateLimit = require('express-rate-limit');

const app = express();
const port = 3000;

// Enhanced middleware for AI/ML testing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Enhanced logging for ML analysis
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    const userAgent = req.get('User-Agent') || 'unknown';
    const ip = req.ip || req.connection.remoteAddress;
    const fingerprint = generateDeviceFingerprint(req);
    
    console.log(JSON.stringify({
        timestamp,
        ip,
        method: req.method,
        url: req.url,
        userAgent,
        deviceFingerprint: fingerprint,
        headers: req.headers,
        body: req.body,
        sessionId: req.sessionID || 'none'
    }));
    next();
});

// Device fingerprinting for fraud detection
function generateDeviceFingerprint(req) {
    const components = [
        req.get('User-Agent') || '',
        req.get('Accept-Language') || '',
        req.get('Accept-Encoding') || '',
        req.ip || ''
    ].join('|');
    
    return crypto.createHash('md5').update(components).digest('hex');
}

// Initialize SQLite database with enhanced tables
const db = new sqlite3.Database(':memory:');
db.serialize(() => {
    // Original vulnerable tables
    db.run(`CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT,
        password TEXT,
        email TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    
    db.run(`CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT,
        price REAL,
        description TEXT
    )`);
    
    db.run(`CREATE TABLE comments (
        id INTEGER PRIMARY KEY,
        content TEXT,
        author TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    
    // Enhanced tables for AI/ML testing
    db.run(`CREATE TABLE login_attempts (
        id INTEGER PRIMARY KEY,
        username TEXT,
        ip_address TEXT,
        user_agent TEXT,
        device_fingerprint TEXT,
        success BOOLEAN,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        risk_score REAL DEFAULT 0.0
    )`);
    
    db.run(`CREATE TABLE transactions (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        amount REAL,
        currency TEXT,
        merchant TEXT,
        ip_address TEXT,
        device_fingerprint TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        fraud_score REAL DEFAULT 0.0,
        status TEXT DEFAULT 'pending'
    )`);
    
    db.run(`CREATE TABLE bot_activity (
        id INTEGER PRIMARY KEY,
        ip_address TEXT,
        user_agent TEXT,
        request_pattern TEXT,
        bot_score REAL DEFAULT 0.0,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    
    // Sample data
    db.run("INSERT INTO users (username, password, email) VALUES ('admin', 'password123', 'admin@example.com')");
    db.run("INSERT INTO users (username, password, email) VALUES ('user1', 'qwerty', 'user1@example.com')");
    db.run("INSERT INTO users (username, password, email) VALUES ('testuser', '123456', 'test@example.com')");
    
    db.run("INSERT INTO products (name, price, description) VALUES ('Laptop', 999.99, 'High-performance laptop')");
    db.run("INSERT INTO products (name, price, description) VALUES ('Phone', 599.99, 'Latest smartphone')");
    db.run("INSERT INTO products (name, price, description) VALUES ('Tablet', 399.99, 'Portable tablet device')");
});

// Basic rate limiting (will be enhanced by WAF AI/ML)
const basicLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', basicLimiter);

// Home page
app.get('/', (req, res) => {
    res.send(`
        <h1>AWS WAF AI/ML Enhanced Demo Application</h1>
        <p>This application demonstrates AI/ML-powered security features:</p>
        <ul>
            <li><a href="/search?q=laptop">Product Search</a> (SQL Injection vulnerable)</li>
            <li><a href="/login">Login Page</a> (Account Takeover testing)</li>
            <li><a href="/payment">Payment Form</a> (Fraud detection testing)</li>
            <li><a href="/api/bot-test">Bot Detection Endpoint</a></li>
            <li><a href="/api/users">User API</a> (SQL Injection vulnerable)</li>
        </ul>
        <h2>AI/ML Testing Endpoints:</h2>
        <ul>
            <li><strong>POST /api/login-attempt</strong> - Enhanced login with risk scoring</li>
            <li><strong>POST /api/transaction</strong> - Payment processing with fraud detection</li>
            <li><strong>GET /api/bot-challenge</strong> - Bot detection challenge</li>
            <li><strong>POST /api/behavioral-analysis</strong> - User behavior analysis</li>
        </ul>
    `);
});

// Original vulnerable endpoints (for baseline testing)
app.get('/search', (req, res) => {
    const query = req.query.q;
    if (!query) {
        return res.send('<form><input name="q" placeholder="Search products..."><button>Search</button></form>');
    }
    
    // Intentionally vulnerable to SQL injection
    const sql = `SELECT * FROM products WHERE name LIKE '%${query}%' OR description LIKE '%${query}%'`;
    
    db.all(sql, (err, rows) => {
        if (err) {
            res.status(500).send(`Database error: ${err.message}`);
        } else {
            res.json({ query, results: rows });
        }
    });
});

app.get('/login', (req, res) => {
    res.send(`
        <form method="POST" action="/api/login-attempt">
            <input name="username" placeholder="Username" required><br>
            <input name="password" type="password" placeholder="Password" required><br>
            <button type="submit">Login</button>
        </form>
    `);
});

app.get('/payment', (req, res) => {
    res.send(`
        <form method="POST" action="/api/transaction">
            <input name="amount" type="number" placeholder="Amount" required><br>
            <input name="card_number" placeholder="Card Number" required><br>
            <input name="merchant" placeholder="Merchant" required><br>
            <button type="submit">Process Payment</button>
        </form>
    `);
});

// Enhanced AI/ML testing endpoints

// Enhanced login with behavioral analysis
app.post('/api/login-attempt', (req, res) => {
    const { username, password } = req.body;
    const ip = req.ip || req.connection.remoteAddress;
    const userAgent = req.get('User-Agent') || '';
    const deviceFingerprint = generateDeviceFingerprint(req);
    
    // Calculate risk score based on various factors
    let riskScore = 0.0;
    
    // Check for suspicious patterns
    if (userAgent.toLowerCase().includes('bot') || userAgent.toLowerCase().includes('crawler')) {
        riskScore += 0.3;
    }
    
    // Check for rapid login attempts from same IP
    db.get(
        "SELECT COUNT(*) as attempts FROM login_attempts WHERE ip_address = ? AND timestamp > datetime('now', '-5 minutes')",
        [ip],
        (err, row) => {
            if (row && row.attempts > 5) {
                riskScore += 0.4;
            }
        }
    );
    
    // Check for credential stuffing patterns
    if (password && (password.length < 6 || password === 'password' || password === '123456')) {
        riskScore += 0.2;
    }
    
    // Simulate ML model prediction
    const mlRiskScore = Math.random() * 0.3; // Simulated ML component
    riskScore += mlRiskScore;
    
    // Log the attempt for ML training
    db.run(
        "INSERT INTO login_attempts (username, ip_address, user_agent, device_fingerprint, success, risk_score) VALUES (?, ?, ?, ?, ?, ?)",
        [username, ip, userAgent, deviceFingerprint, false, riskScore]
    );
    
    // Determine response based on risk score
    if (riskScore > 0.7) {
        res.status(403).json({
            error: "Login blocked by AI/ML risk assessment",
            riskScore: riskScore,
            reason: "High-risk login pattern detected",
            challengeRequired: true
        });
    } else if (riskScore > 0.4) {
        res.status(200).json({
            message: "Additional verification required",
            riskScore: riskScore,
            challengeType: "captcha",
            challengeRequired: true
        });
    } else {
        // Vulnerable SQL injection for demonstration
        const sql = `SELECT * FROM users WHERE username = '${username}' AND password = '${password}'`;
        db.get(sql, (err, row) => {
            if (err) {
                res.status(500).json({ error: err.message });
            } else if (row) {
                res.json({ 
                    success: true, 
                    user: row, 
                    riskScore: riskScore,
                    message: "Login successful" 
                });
            } else {
                res.status(401).json({ 
                    error: "Invalid credentials", 
                    riskScore: riskScore 
                });
            }
        });
    }
});

// Enhanced transaction processing with fraud detection
app.post('/api/transaction', (req, res) => {
    const { amount, card_number, merchant } = req.body;
    const ip = req.ip || req.connection.remoteAddress;
    const deviceFingerprint = generateDeviceFingerprint(req);
    
    // Calculate fraud score
    let fraudScore = 0.0;
    
    // Amount-based risk
    if (amount > 1000) fraudScore += 0.2;
    if (amount > 5000) fraudScore += 0.3;
    
    // Velocity checks (multiple transactions from same device/IP)
    db.get(
        "SELECT COUNT(*) as count, SUM(amount) as total FROM transactions WHERE (ip_address = ? OR device_fingerprint = ?) AND timestamp > datetime('now', '-1 hour')",
        [ip, deviceFingerprint],
        (err, row) => {
            if (row) {
                if (row.count > 5) fraudScore += 0.3;
                if (row.total > 10000) fraudScore += 0.4;
            }
        }
    );
    
    // Simulate ML fraud model
    const mlFraudScore = Math.random() * 0.4; // Simulated ML component
    fraudScore += mlFraudScore;
    
    // Geographic risk (simulated)
    const geoRisk = Math.random() * 0.2;
    fraudScore += geoRisk;
    
    // Log transaction
    db.run(
        "INSERT INTO transactions (user_id, amount, currency, merchant, ip_address, device_fingerprint, fraud_score) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [1, amount, 'USD', merchant, ip, deviceFingerprint, fraudScore]
    );
    
    // Determine response based on fraud score
    if (fraudScore > 0.8) {
        res.status(403).json({
            error: "Transaction blocked by fraud detection",
            fraudScore: fraudScore,
            reason: "High fraud risk detected",
            blocked: true
        });
    } else if (fraudScore > 0.5) {
        res.status(200).json({
            message: "Transaction requires additional verification",
            fraudScore: fraudScore,
            status: "pending_verification",
            verificationRequired: true
        });
    } else {
        res.json({
            success: true,
            transactionId: crypto.randomUUID(),
            fraudScore: fraudScore,
            status: "approved"
        });
    }
});

// Bot detection challenge endpoint
app.get('/api/bot-challenge', (req, res) => {
    const userAgent = req.get('User-Agent') || '';
    const ip = req.ip || req.connection.remoteAddress;
    
    // Calculate bot score
    let botScore = 0.0;
    
    // User agent analysis
    if (!userAgent || userAgent.length < 10) botScore += 0.4;
    if (userAgent.toLowerCase().includes('bot')) botScore += 0.5;
    if (userAgent.toLowerCase().includes('crawler')) botScore += 0.5;
    if (userAgent.toLowerCase().includes('spider')) botScore += 0.5;
    
    // Request pattern analysis (simulated)
    const requestPattern = req.get('Accept') || '';
    if (!requestPattern.includes('text/html')) botScore += 0.2;
    
    // Simulate ML bot detection
    const mlBotScore = Math.random() * 0.3;
    botScore += mlBotScore;
    
    // Log bot activity
    db.run(
        "INSERT INTO bot_activity (ip_address, user_agent, request_pattern, bot_score) VALUES (?, ?, ?, ?)",
        [ip, userAgent, requestPattern, botScore]
    );
    
    if (botScore > 0.7) {
        res.status(403).json({
            error: "Bot detected",
            botScore: botScore,
            challenge: "Please solve: What is 2 + 2?",
            blocked: true
        });
    } else if (botScore > 0.4) {
        res.json({
            message: "Suspicious activity detected",
            botScore: botScore,
            challenge: "JavaScript challenge required",
            challengeRequired: true
        });
    } else {
        res.json({
            success: true,
            botScore: botScore,
            message: "Human traffic detected"
        });
    }
});

// Behavioral analysis endpoint
app.post('/api/behavioral-analysis', (req, res) => {
    const { mouseMovements, keystrokes, timeOnPage } = req.body;
    const ip = req.ip || req.connection.remoteAddress;
    
    // Analyze behavioral patterns
    let humanScore = 1.0;
    
    if (!mouseMovements || mouseMovements.length < 5) humanScore -= 0.3;
    if (!keystrokes || keystrokes < 10) humanScore -= 0.2;
    if (timeOnPage < 2000) humanScore -= 0.3; // Less than 2 seconds
    
    // Simulate ML behavioral analysis
    const mlHumanScore = Math.random() * 0.2;
    humanScore += mlHumanScore;
    
    res.json({
        humanScore: Math.max(0, Math.min(1, humanScore)),
        botScore: 1 - humanScore,
        analysis: {
            mouseMovements: mouseMovements ? mouseMovements.length : 0,
            keystrokes: keystrokes || 0,
            timeOnPage: timeOnPage || 0
        },
        recommendation: humanScore > 0.6 ? "allow" : "challenge"
    });
});

// Original vulnerable endpoints for baseline comparison
app.get('/api/users', (req, res) => {
    const filter = req.query.filter || '';
    // Intentionally vulnerable to SQL injection
    const sql = `SELECT id, username, email FROM users WHERE username LIKE '%${filter}%'`;
    
    db.all(sql, (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
        } else {
            res.json(rows);
        }
    });
});

app.post('/comment', (req, res) => {
    const { content, author } = req.body;
    // Intentionally vulnerable to XSS
    db.run("INSERT INTO comments (content, author) VALUES (?, ?)", [content, author], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
        } else {
            res.send(`<p>Comment added: <strong>${author}</strong> said: ${content}</p>`);
        }
    });
});

// Analytics endpoint for ML insights
app.get('/api/analytics', (req, res) => {
    const analytics = {};
    
    // Get login attempt statistics
    db.get("SELECT COUNT(*) as total, AVG(risk_score) as avg_risk FROM login_attempts", (err, loginStats) => {
        analytics.loginAttempts = loginStats;
        
        // Get transaction statistics
        db.get("SELECT COUNT(*) as total, AVG(fraud_score) as avg_fraud FROM transactions", (err, transactionStats) => {
            analytics.transactions = transactionStats;
            
            // Get bot activity statistics
            db.get("SELECT COUNT(*) as total, AVG(bot_score) as avg_bot_score FROM bot_activity", (err, botStats) => {
                analytics.botActivity = botStats;
                
                res.json({
                    timestamp: new Date().toISOString(),
                    analytics: analytics,
                    mlInsights: {
                        threatLevel: Math.random() > 0.5 ? "elevated" : "normal",
                        adaptiveThreshold: 0.6 + (Math.random() * 0.2),
                        learningStatus: "active"
                    }
                });
            });
        });
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`AWS WAF AI/ML Enhanced Demo App listening at http://0.0.0.0:${port}`);
    console.log('Enhanced endpoints available for AI/ML testing:');
    console.log('- POST /api/login-attempt (Account Takeover Prevention)');
    console.log('- POST /api/transaction (Fraud Detection)');
    console.log('- GET /api/bot-challenge (Bot Detection)');
    console.log('- POST /api/behavioral-analysis (Behavioral Analysis)');
    console.log('- GET /api/analytics (ML Insights)');
});
