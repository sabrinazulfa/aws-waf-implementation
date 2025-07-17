const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));

// In-memory "database" for demo
let users = [
  { id: 1, username: 'admin', password: 'admin123', email: 'admin@demo.com' },
  { id: 2, username: 'user1', password: 'password', email: 'user1@demo.com' },
  { id: 3, username: 'john', password: 'john123', email: 'john@demo.com' }
];

let products = [
  { id: 1, name: 'Laptop', price: 999, description: 'High-performance laptop' },
  { id: 2, name: 'Phone', price: 599, description: 'Latest smartphone' },
  { id: 3, name: 'Tablet', price: 399, description: 'Portable tablet' }
];

// Request logging for demo purposes
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Query params:', req.query);
  console.log('Body:', req.body);
  console.log('Headers:', req.headers);
  console.log('---');
  next();
});

// Home page
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Vulnerable Demo App</title></head>
      <body>
        <h1>🚨 Vulnerable Demo Application</h1>
        <p><strong>WARNING:</strong> This app is intentionally vulnerable for AWS WAF demonstration purposes.</p>
        
        <h2>Available Endpoints:</h2>
        <ul>
          <li><a href="/search?q=laptop">GET /search?q=laptop</a> - Product search (SQL Injection vulnerable)</li>
          <li><a href="/api/users">GET /api/users</a> - List users (SQL Injection vulnerable)</li>
          <li><a href="/login">POST /login</a> - Login endpoint (Brute force target)</li>
          <li><a href="/api/user-profile?id=1">GET /api/user-profile?id=1</a> - User profile (SQL Injection vulnerable)</li>
          <li><a href="/comment">POST /comment</a> - Add comment (XSS vulnerable)</li>
        </ul>

        <h2>Test Forms:</h2>
        
        <h3>Search Products:</h3>
        <form action="/search" method="GET">
          <input type="text" name="q" placeholder="Search products..." value="laptop">
          <button type="submit">Search</button>
        </form>
        <p><em>Try: <code>' OR '1'='1</code> or <code>'; DROP TABLE products; --</code></em></p>

        <h3>Login:</h3>
        <form action="/login" method="POST">
          <input type="text" name="username" placeholder="Username" value="admin">
          <input type="password" name="password" placeholder="Password" value="admin123">
          <button type="submit">Login</button>
        </form>

        <h3>Add Comment:</h3>
        <form action="/comment" method="POST">
          <textarea name="comment" placeholder="Your comment..."></textarea>
          <button type="submit">Submit</button>
        </form>
        <p><em>Try: <code>&lt;script&gt;alert('XSS')&lt;/script&gt;</code></em></p>

        <div id="comments"></div>
      </body>
    </html>
  `);
});

// VULNERABLE ENDPOINT 1: SQL Injection in search
app.get('/search', (req, res) => {
  const query = req.query.q;
  
  if (!query) {
    return res.json({ error: 'No search query provided' });
  }

  console.log(`🚨 VULNERABLE: Executing search query: ${query}`);
  
  // Simulate SQL injection vulnerability
  if (query.includes('DROP') || query.includes('DELETE') || query.includes('UPDATE')) {
    return res.status(500).json({
      error: "💥 CRITICAL: Database operation executed!",
      query: query,
      message: "In a real app, this would have damaged your database!",
      vulnerability: "SQL Injection"
    });
  }
  
  if (query.includes("'") && query.includes('OR')) {
    // Simulate returning all products due to SQL injection
    return res.json({
      message: "🚨 SQL Injection detected! Returning all products...",
      query: query,
      results: products,
      vulnerability: "SQL Injection - bypassed WHERE clause"
    });
  }

  // Normal search
  const results = products.filter(p => 
    p.name.toLowerCase().includes(query.toLowerCase()) ||
    p.description.toLowerCase().includes(query.toLowerCase())
  );

  res.json({ 
    query: query,
    results: results,
    count: results.length 
  });
});

// VULNERABLE ENDPOINT 2: SQL Injection in user listing
app.get('/api/users', (req, res) => {
  const filter = req.query.filter;
  
  if (filter) {
    console.log(`🚨 VULNERABLE: User filter query: ${filter}`);
    
    if (filter.includes('DROP') || filter.includes('DELETE')) {
      return res.status(500).json({
        error: "💥 CRITICAL: Database destroyed!",
        filter: filter,
        vulnerability: "SQL Injection"
      });
    }
    
    if (filter.includes("'") && filter.includes('OR')) {
      return res.json({
        message: "🚨 SQL Injection! Exposing all user data...",
        users: users.map(u => ({ ...u, password: '***EXPOSED***' })),
        vulnerability: "SQL Injection - data breach"
      });
    }
  }

  // Return users without passwords (normal behavior)
  res.json({
    users: users.map(u => ({ id: u.id, username: u.username, email: u.email }))
  });
});

// VULNERABLE ENDPOINT 3: Brute force target
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  
  console.log(`🚨 LOGIN ATTEMPT: ${username}:${password}`);
  
  // Simulate slow login process (makes brute force more obvious)
  setTimeout(() => {
    const user = users.find(u => u.username === username && u.password === password);
    
    if (user) {
      res.json({
        success: true,
        message: "Login successful!",
        user: { id: user.id, username: user.username, email: user.email }
      });
    } else {
      res.status(401).json({
        success: false,
        error: "Invalid credentials",
        attempt: `${username}:${password}`
      });
    }
  }, 100); // Small delay to make brute force attacks more visible
});

// VULNERABLE ENDPOINT 4: User profile with SQL injection
app.get('/api/user-profile', (req, res) => {
  const userId = req.query.id;
  
  if (!userId) {
    return res.status(400).json({ error: 'User ID required' });
  }

  console.log(`🚨 VULNERABLE: User profile query for ID: ${userId}`);
  
  // Simulate SQL injection in user profile lookup
  if (userId.includes('UNION') || userId.includes('SELECT')) {
    return res.json({
      message: "🚨 SQL Injection detected! Exposing sensitive data...",
      query: userId,
      exposed_data: {
        admin_passwords: users.map(u => ({ username: u.username, password: u.password })),
        system_info: "Database version: MySQL 8.0, Admin privileges: YES"
      },
      vulnerability: "SQL Injection - UNION attack"
    });
  }

  const user = users.find(u => u.id == userId);
  if (user) {
    res.json({
      profile: { id: user.id, username: user.username, email: user.email }
    });
  } else {
    res.status(404).json({ error: 'User not found' });
  }
});

// VULNERABLE ENDPOINT 5: XSS in comments
let comments = [];

app.post('/comment', (req, res) => {
  const { comment } = req.body;
  
  if (!comment) {
    return res.status(400).json({ error: 'Comment required' });
  }

  console.log(`🚨 VULNERABLE: Comment submitted: ${comment}`);
  
  // Store comment without sanitization (XSS vulnerability)
  const newComment = {
    id: comments.length + 1,
    comment: comment, // No sanitization!
    timestamp: new Date().toISOString()
  };
  
  comments.push(newComment);
  
  if (comment.includes('<script>') || comment.includes('javascript:')) {
    res.json({
      message: "🚨 XSS payload detected and stored!",
      comment: newComment,
      vulnerability: "Stored XSS",
      warning: "In a real app, this script would execute for all users!"
    });
  } else {
    res.json({
      message: "Comment added successfully",
      comment: newComment
    });
  }
});

app.get('/comments', (req, res) => {
  res.json({ comments: comments });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Catch-all for undefined routes
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    available_endpoints: [
      'GET /',
      'GET /search?q=<query>',
      'GET /api/users?filter=<filter>',
      'POST /login',
      'GET /api/user-profile?id=<id>',
      'POST /comment',
      'GET /comments',
      'GET /health'
    ]
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

app.listen(PORT, () => {
  console.log(`🚨 Vulnerable Demo App running on port ${PORT}`);
  console.log(`🌐 Access at: http://localhost:${PORT}`);
  console.log(`⚠️  WARNING: This app is intentionally vulnerable for demo purposes!`);
  console.log(`📋 Available endpoints:`);
  console.log(`   GET  /                     - Home page with test forms`);
  console.log(`   GET  /search?q=<query>     - Product search (SQL Injection)`);
  console.log(`   GET  /api/users            - List users (SQL Injection)`);
  console.log(`   POST /login                - Login (Brute force target)`);
  console.log(`   GET  /api/user-profile     - User profile (SQL Injection)`);
  console.log(`   POST /comment              - Add comment (XSS)`);
  console.log(`   GET  /health               - Health check`);
});

module.exports = app;
