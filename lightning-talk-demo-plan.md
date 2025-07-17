# Lightning Talk Demo Plan: AWS WAF Beginner's Journey

## Talk Structure (15-20 minutes)
**"From Production Pain to Protection: My AWS WAF Learning Journey"**

### 1. The Production Reality Check (3 minutes)
**Start with YOUR story:**
- "Here's what happened in production that made me learn WAF..."
- Show real (anonymized) CloudWatch logs/metrics from your incident
- The business impact and wake-up call

### 2. Simple Web App for Demo (5 minutes)

#### Option A: Vulnerable Blog Application
```bash
# Simple Express.js app with common vulnerabilities
git clone https://github.com/OWASP/NodeGoat
# Or create a basic app with these endpoints:
```

**Demo App Features:**
- `/api/users` - SQL injection vulnerable endpoint
- `/login` - Brute force target
- `/upload` - File upload (XSS potential)
- `/search` - Reflected XSS vulnerability

#### Option B: E-commerce Product Page
```javascript
// Simple product search with vulnerabilities
app.get('/search', (req, res) => {
  const query = req.query.q; // No sanitization
  const sql = `SELECT * FROM products WHERE name LIKE '%${query}%'`;
  // Vulnerable to SQL injection
});
```

### 3. Live Attack Simulation (7 minutes)

#### Attack 1: SQL Injection
```bash
# Before WAF
curl "https://your-demo-app.com/search?q='; DROP TABLE users; --"
# Show successful attack in logs
```

#### Attack 2: Brute Force
```bash
# Simulate login attempts
for i in {1..100}; do
  curl -X POST https://your-demo-app.com/login \
    -d "username=admin&password=password$i"
done
```

#### Attack 3: XSS Attempt
```bash
curl "https://your-demo-app.com/search?q=<script>alert('XSS')</script>"
```

### 4. WAF Implementation (3 minutes)

**Show the "before and after" approach:**

```yaml
# CloudFormation snippet - what you actually used
Resources:
  WebACL:
    Type: AWS::WAFv2::WebACL
    Properties:
      Rules:
        - Name: AWSManagedRulesCommonRuleSet
          Priority: 1
          OverrideAction:
            None: {}
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesCommonRuleSet
        - Name: RateLimitRule
          Priority: 2
          Action:
            Block: {}
          Statement:
            RateBasedStatement:
              Limit: 100
              AggregateKeyType: IP
```

### 5. Results & Lessons (2 minutes)

## Demo Environment Setup

### Quick Setup Script
```bash
#!/bin/bash
# demo-setup.sh

# 1. Deploy simple vulnerable app
aws cloudformation deploy \
  --template-file vulnerable-app.yaml \
  --stack-name waf-demo-app

# 2. Get ALB endpoint
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[0].DNSName' --output text)

# 3. Deploy WAF
aws cloudformation deploy \
  --template-file waf-protection.yaml \
  --stack-name waf-demo-protection \
  --parameter-overrides AlbArn=$ALB_ARN

echo "Demo ready at: http://$ALB_DNS"
```

### Vulnerable Demo App (Node.js)
```javascript
// app.js - Intentionally vulnerable for demo
const express = require('express');
const app = express();

// Vulnerable search endpoint
app.get('/search', (req, res) => {
  const query = req.query.q;
  // Simulate SQL injection vulnerability
  if (query.includes('DROP') || query.includes('DELETE')) {
    res.status(500).json({
      error: "Database error - table dropped!",
      query: query
    });
  } else {
    res.json({ results: `Searching for: ${query}` });
  }
});

// Rate limiting target
app.post('/api/login', (req, res) => {
  // Always fail for demo
  res.status(401).json({ error: "Invalid credentials" });
});

app.listen(3000);
```

## Your Production Story Framework

### The Incident
- "We had X requests per second hitting our login endpoint"
- "Our database started throwing errors from malformed queries"
- "Customer complaints started coming in"

### The Learning Process
- "I had never configured WAF before"
- "The AWS documentation was overwhelming"
- "Here's what I wish I knew on day one"

### The Solution
- "Started with managed rule groups"
- "Added rate limiting based on our traffic patterns"
- "Monitored and tuned over 2 weeks"

## Demo Script

### Pre-Demo Setup
```bash
# Have these ready before the talk
export DEMO_URL="https://your-demo-alb.amazonaws.com"
export WAF_WEB_ACL_ID="your-web-acl-id"

# Test attacks ready in terminal tabs
# Tab 1: SQL injection
# Tab 2: Rate limiting
# Tab 3: XSS attempt
```

### Live Demo Flow
1. **Show normal app functionality** (30 seconds)
2. **Execute attacks without WAF** - show failures (2 minutes)
3. **Enable WAF with one command** (30 seconds)
4. **Repeat same attacks** - show blocks (2 minutes)
5. **Show WAF dashboard** - real-time metrics (1 minute)

## Key Messages for Lightning Talk

### What Worked
- "Managed rule groups got me 80% protection immediately"
- "Rate limiting solved our brute force problem in minutes"
- "CloudWatch integration made monitoring simple"

### What I Learned
- "Start simple - don't over-engineer on day one"
- "Monitor first, then tune rules based on real traffic"
- "Test in staging with real attack patterns"

### Beginner Tips
1. **Start with AWS Managed Rules** - don't write custom rules initially
2. **Use Count mode first** - see what would be blocked before blocking
3. **Set up CloudWatch alarms** - know when you're under attack
4. **Document your rules** - you'll forget why you added them

## Backup Plans

### If Live Demo Fails
- Pre-recorded video of the attack/block sequence
- Screenshots of before/after CloudWatch metrics
- Static slides showing the WAF rule configuration

### If Time Runs Short
- Skip the app setup explanation
- Focus on the attack simulation and WAF response
- End with "here's the GitHub repo with everything"

## Follow-up Resources
```markdown
## Take This Home
- GitHub repo: github.com/yourusername/waf-lightning-demo
- Blog post: "My First Week with AWS WAF"
- CloudFormation templates for everything shown
- Attack simulation scripts
```

This approach leverages your real production experience while keeping the demo simple and focused for a lightning talk format. The key is showing the immediate value of WAF rather than getting lost in configuration details.
