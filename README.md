# AWS WAF Lightning Talk Demo

> **"From Production Pain to Protection: My AWS WAF Learning Journey"**

A complete demo environment for showcasing AWS WAF protection capabilities in a lightning talk format, featuring a vulnerable web application and comprehensive attack simulations.

## 🎯 Talk Overview

This repository contains everything needed for a compelling AWS Summit lightning talk that demonstrates:
- Real-world web application vulnerabilities
- Live attack simulations
- AWS WAF protection implementation
- Before/after security comparison

**Perfect for:** Developers, DevOps engineers, and security-conscious teams who want to understand practical WAF implementation.

## 📁 Project Structure

```
aws-summit-lightning-talk/
├── README.md                          # This file
├── lightning-talk-demo-plan.md        # Detailed talk structure and flow
├── app/                              # Vulnerable demo application
│   ├── app.js                        # Node.js vulnerable web app
│   ├── package.json                  # Dependencies
│   └── Dockerfile                    # Container configuration
├── cloudformation/                   # Infrastructure as Code
│   ├── 01-vulnerable-app.yaml        # ALB + EC2 infrastructure
│   └── 02-waf-protection.yaml        # WAF rules and monitoring
├── attacks/                          # Attack simulation scripts
│   ├── sql-injection-test.sh         # SQL injection attacks
│   ├── brute-force-test.sh          # Login brute force
│   ├── xss-test.sh                  # Cross-site scripting
│   └── run-all-attacks.sh           # Comprehensive testing
└── scripts/                         # Deployment automation
    ├── deploy-demo.sh               # One-click deployment
    └── cleanup-demo.sh              # Resource cleanup
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- EC2 Key Pair in your target region
- Basic understanding of CloudFormation

### 1. Deploy the Demo Environment
```bash
cd scripts/
./deploy-demo.sh us-east-1 my-key-pair
```

### 2. Test Vulnerabilities (Before WAF)
```bash
cd attacks/
./run-all-attacks.sh http://your-alb-dns-name
```

### 3. Deploy WAF Protection
```bash
# If not deployed during initial setup
aws cloudformation deploy \
  --template-file cloudformation/02-waf-protection.yaml \
  --stack-name waf-lightning-demo-waf \
  --parameter-overrides LoadBalancerArn=your-alb-arn
```

### 4. Test Again (After WAF)
```bash
./run-all-attacks.sh http://your-alb-dns-name
# Watch attacks get blocked! 🛡️
```

## 🎭 The Vulnerable Demo App

The demo application intentionally includes common vulnerabilities:

### Vulnerable Endpoints
- **`/search`** - SQL injection in product search
- **`/login`** - Brute force target (no rate limiting)
- **`/api/users`** - SQL injection in user filtering
- **`/comment`** - Stored XSS vulnerability
- **`/api/user-profile`** - UNION-based SQL injection

### Example Attacks
```bash
# SQL Injection
curl "http://demo-app/search?q='; DROP TABLE users; --"

# XSS
curl "http://demo-app/search?q=<script>alert('XSS')</script>"

# Brute Force
for i in {1..100}; do 
  curl -X POST http://demo-app/login -d "user=admin&pass=$i"
done
```

## 🛡️ WAF Protection Features

### Managed Rule Groups
- **AWSManagedRulesCommonRuleSet** - OWASP Top 10 protection
- **AWSManagedRulesSQLiRuleSet** - SQL injection prevention
- **AWSManagedRulesKnownBadInputsRuleSet** - Known attack patterns

### Custom Rules
- **Rate Limiting** - Prevents brute force attacks
- **Geographic Blocking** - Optional country-based restrictions
- **Custom SQL Injection Detection** - Specific payload blocking
- **XSS Protection** - Script injection prevention

### Monitoring & Alerting
- CloudWatch metrics and dashboards
- Real-time attack visualization
- Automated alerting for security events
- Comprehensive logging

## 📊 Lightning Talk Structure

### 1. The Production Story (3 minutes)
- Share your real production incident
- Business impact and urgency
- "I had never used WAF before..."

### 2. Live Vulnerability Demo (5 minutes)
- Show the vulnerable application
- Execute SQL injection attacks
- Demonstrate brute force attempts
- Display successful XSS payloads

### 3. WAF Implementation (3 minutes)
- Deploy WAF with one command
- Explain managed rule groups
- Show custom rule configuration

### 4. Protection in Action (5 minutes)
- Repeat the same attacks
- Show blocked requests in real-time
- Display CloudWatch metrics
- Demonstrate rate limiting

### 5. Key Learnings (4 minutes)
- What worked immediately
- Common beginner mistakes
- Monitoring and tuning tips
- Cost considerations

## 🎯 Key Demo Points

### Before WAF
- ❌ SQL injection succeeds
- ❌ XSS payloads execute
- ❌ Unlimited login attempts
- ❌ No attack visibility

### After WAF
- ✅ SQL injection blocked
- ✅ XSS filtered out
- ✅ Rate limiting active
- ✅ Real-time monitoring

## 💡 Beginner Tips (From Real Experience)

1. **Start Simple** - Use managed rule groups first
2. **Test in Count Mode** - See what would be blocked before blocking
3. **Monitor Actively** - Set up CloudWatch alarms
4. **Document Everything** - You'll forget why you added rules
5. **Test Regularly** - Verify protection with attack simulations

## 📈 Cost Considerations

### Demo Environment Costs
- **EC2 instances**: ~$0.0116/hour (t3.micro)
- **Application Load Balancer**: ~$0.0225/hour
- **WAF Web ACL**: $1.00/month + $0.60 per million requests
- **CloudWatch**: Minimal for demo usage

**Total demo cost**: ~$2-5 for a few hours of demo

## 🧹 Cleanup

```bash
cd scripts/
./cleanup-demo.sh us-east-1 waf-lightning-demo
```

This removes all AWS resources and stops billing.

## 🔧 Customization

### Modify the Vulnerable App
Edit `app/app.js` to add new vulnerabilities or change endpoints.

### Adjust WAF Rules
Modify `cloudformation/02-waf-protection.yaml` to:
- Change rate limiting thresholds
- Add geographic restrictions
- Include additional managed rule groups
- Create custom detection rules

### Add New Attack Simulations
Create new scripts in the `attacks/` directory following the existing patterns.

## 📚 Additional Resources

### AWS Documentation
- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/)
- [WAF Security Automations](https://aws.amazon.com/solutions/implementations/security-automations-for-aws-waf/)

### Security Testing Tools
- [OWASP ZAP](https://owasp.org/www-project-zap/)
- [Burp Suite](https://portswigger.net/burp)
- [SQLMap](https://sqlmap.org/)

### Learning Resources
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## 🤝 Contributing

Found an issue or want to improve the demo? 

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## ⚠️ Important Notes

### Security Disclaimer
This application is **intentionally vulnerable** for educational purposes. Never deploy this in a production environment or expose it to the internet without WAF protection.

### Demo Environment
- Use only for demonstrations and learning
- Clean up resources after use to avoid charges
- Don't store real data in the demo application

### Production Considerations
- This demo simplifies many production concerns
- Real implementations need additional security layers
- Consider compliance requirements for your use case

## 📞 Support

Having issues with the demo? Check these common solutions:

### Deployment Issues
- Verify AWS credentials and permissions
- Ensure EC2 key pair exists in target region
- Check CloudFormation stack events for errors

### Application Not Responding
- Wait 5-10 minutes for EC2 instances to initialize
- Check target group health in ALB console
- Verify security group rules allow traffic

### WAF Not Blocking
- Confirm WAF is associated with ALB
- Check rule priorities and actions
- Verify test payloads match rule patterns

---

## 🎉 Ready for Your Lightning Talk!

This demo provides everything you need for a compelling AWS Summit presentation that combines:
- **Real production experience** (your story)
- **Live technical demonstration** (vulnerable app + attacks)
- **Immediate problem solving** (WAF deployment)
- **Measurable results** (blocked attacks + metrics)

The combination of storytelling and technical demonstration makes for an engaging and memorable lightning talk that attendees can immediately apply to their own environments.

**Good luck with your presentation!** 🚀
