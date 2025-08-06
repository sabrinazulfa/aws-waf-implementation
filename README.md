# AWS WAF Security Demonstration Environment

A comprehensive demonstration environment showcasing AWS WAF protection capabilities, featuring a deliberately vulnerable web application and attack simulation tools for security testing and validation.

## Overview

This repository provides a complete environment for demonstrating:
- Common web application vulnerabilities and attack vectors
- AWS WAF protection implementation and configuration
- Real-time attack mitigation and monitoring
- Security posture comparison with and without WAF protection

**Target Audience:** Security teams, DevOps engineers, and cloud architects implementing AWS WAF.

## Project Structure

```
.
├── README.md                          # Project documentation
├── app/                              # Demo web application
│   ├── app.js                        # Node.js application
│   ├── package.json                  # Dependencies
│   └── Dockerfile                    # Container configuration
├── cloudformation/                   # Infrastructure as Code
│   ├── 01-vulnerable-app.yaml        # Base infrastructure
│   └── 02-waf-protection.yaml        # WAF configuration
├── attacks/                          # Security testing scripts
│   ├── sql-injection-test.sh         # SQL injection vectors
│   ├── brute-force-test.sh          # Authentication attacks
│   ├── xss-test.sh                  # XSS attack simulation
│   └── run-all-attacks.sh           # Comprehensive testing
└── scripts/                         # Deployment automation
    ├── deploy-demo.sh               # Deployment script
    └── cleanup-demo.sh              # Resource cleanup
```

## Prerequisites

- AWS CLI with configured credentials
- EC2 Key Pair in target region
- Appropriate IAM permissions for CloudFormation, WAF, and related services

## Deployment Instructions

### 1. Infrastructure Deployment
```bash
cd scripts/
./deploy-demo.sh us-east-1 my-key-pair
```

### 2. Security Testing (Pre-WAF)
```bash
cd attacks/
./run-all-attacks.sh http://your-alb-dns-name
```

### 3. WAF Implementation
```bash
aws cloudformation deploy \
  --template-file cloudformation/02-waf-protection.yaml \
  --stack-name waf-demo-protection \
  --region $REGION
```

### 4. Security Validation (Post-WAF)
```bash
./run-all-attacks.sh http://your-alb-dns-name
```

## Application Security Features

The demonstration application includes deliberately implemented vulnerabilities for security testing:

### Vulnerable Endpoints
- `/search` - SQL injection vulnerability
- `/login` - Authentication endpoint
- `/api/users` - SQL injection in user filtering
- `/comment` - Stored XSS vulnerability
- `/api/user-profile` - UNION-based SQL injection

### Attack Vectors
```bash
# SQL Injection Example
curl "http://demo-app/search?q='; DROP TABLE users; --"

# XSS Vector
curl "http://demo-app/search?q=<script>alert('XSS')</script>"

# Authentication Attack
for i in {1..100}; do
  curl -X POST http://demo-app/login -d "user=admin&pass=$i"
done
```

## WAF Protection Implementation

### Managed Rule Groups
- AWSManagedRulesCommonRuleSet
- AWSManagedRulesSQLiRuleSet
- AWSManagedRulesKnownBadInputsRuleSet

### Custom Security Rules
- Rate-based attack prevention
- Geographic access control
- Custom SQL injection detection
- XSS mitigation rules

### Security Monitoring
- Real-time CloudWatch metrics
- Attack pattern visualization
- Security event alerting
- Comprehensive logging

## Cost Considerations

### Infrastructure Components
- EC2 instances (t3.micro): ~$0.0116/hour
- Application Load Balancer: ~$0.0225/hour
- WAF Web ACL: $1.00/month + $0.60 per million requests
- CloudWatch: Minimal for demonstration usage

## Resource Cleanup

```bash
cd scripts/
./cleanup-demo.sh us-east-1 waf-demo
```

## Customization Options

### Application Modifications
Edit `app/app.js` to modify vulnerabilities or endpoints.

### WAF Rule Customization
Modify `cloudformation/02-waf-protection.yaml` to:
- Adjust rate limiting thresholds
- Configure geographic restrictions
- Add custom rule groups
- Modify detection patterns

### Attack Simulation
Create custom attack scripts in the `attacks/` directory.

## Additional Resources

### AWS Documentation
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [WAF Security Automations](https://aws.amazon.com/solutions/implementations/security-automations-for-aws-waf/)

### Security Tools
- [OWASP ZAP](https://owasp.org/www-project-zap/)
- [Burp Suite](https://portswigger.net/burp)
- [SQLMap](https://sqlmap.org/)

### Security References
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes
4. Add comprehensive tests
5. Submit a pull request

## Security Notice

This application contains intentional vulnerabilities for demonstration purposes. Never deploy in a production environment without proper security controls.

## Support

For deployment issues:
- Verify AWS credentials and permissions
- Check CloudFormation stack events
- Validate EC2 key pair availability
- Review security group configurations

For application issues:
- Allow 5-10 minutes for EC2 initialization
- Verify target group health status
- Check security group rules
- Review application logs
