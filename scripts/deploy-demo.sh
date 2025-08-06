#!/bin/bash

# AWS WAF Lightning Talk Demo Deployment Script
# Usage: ./deploy-demo.sh [region] [key-pair-name]

set -e

REGION=${1:-"us-east-1"}
KEY_PAIR=${2:-"my-key-pair"}
STACK_PREFIX="waf-lightning-demo"

echo "🚀 AWS WAF Lightning Talk Demo Deployment"
echo "=========================================="
echo "Region: $REGION"
echo "Key Pair: $KEY_PAIR"
echo "Stack Prefix: $STACK_PREFIX"
echo "Time: $(date)"
echo "=========================================="

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI configured and credentials valid"

# Check if key pair exists
if ! aws ec2 describe-key-pairs --key-names "$KEY_PAIR" --region "$REGION" &> /dev/null; then
    echo "❌ Key pair '$KEY_PAIR' not found in region '$REGION'"
    echo "Please create a key pair first or specify an existing one."
    exit 1
fi

echo "✅ Key pair '$KEY_PAIR' found"

# Function to wait for stack completion
wait_for_stack() {
    local stack_name="$1"
    local operation="$2"

    echo "⏳ Waiting for stack $operation to complete: $stack_name"

    if [ "${operation}" = "create-or-update" ]; then
        aws cloudformation wait "stack-create-complete" \
            --stack-name "$stack_name" \
            --region "$REGION" || \
        aws cloudformation wait "stack-update-complete" \
            --stack-name "$stack_name" \
            --region "$REGION"
    else
        aws cloudformation wait "stack-${operation}-complete" \
            --stack-name "$stack_name" \
            --region "$REGION"
    fi

    if [ $? -eq 0 ]; then
        echo "✅ Stack $operation completed: $stack_name"
    else
        echo "❌ Stack $operation failed: $stack_name"
        aws cloudformation describe-stack-events \
            --stack-name "$stack_name" \
            --region "$REGION" \
            --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].[Timestamp,ResourceType,LogicalResourceId,ResourceStatusReason]' \
            --output table
        exit 1
    fi
}

# Deploy the vulnerable application stack
echo -e "\n📦 Deploying vulnerable application infrastructure..."
aws cloudformation deploy \
    --template-file "$(dirname "$(pwd)")/cloudformation/01-vulnerable-app-ubuntu-fixed.yaml" \
    --stack-name "${STACK_PREFIX}-app" \
    --parameter-overrides KeyPairName="$KEY_PAIR" \
    --capabilities CAPABILITY_IAM \
    --region "$REGION" \
    --tags \
        Purpose="Lightning Talk Demo" \
        Environment="Demo" \
        Owner="$(aws sts get-caller-identity --query 'Arn' --output text)"

wait_for_stack "${STACK_PREFIX}-app" "create-or-update"

# Get ALB ARN for WAF deployment
echo -e "\n🔍 Getting Application Load Balancer ARN..."
ALB_ARN=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_PREFIX}-app" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
    --output text)

if [ -z "$ALB_ARN" ]; then
    echo "❌ Could not retrieve ALB ARN from stack outputs"
    exit 1
fi

echo "✅ ALB ARN: $ALB_ARN"

# Get ALB DNS name
ALB_DNS=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_PREFIX}-app" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text)

echo "✅ ALB DNS: $ALB_DNS"

# Wait for ALB to be active
echo -e "\n⏳ Waiting for Application Load Balancer to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN" --region "$REGION"
echo "✅ Application Load Balancer is active"

# Test the vulnerable application
echo -e "\n🧪 Testing vulnerable application..."
for i in {1..10}; do
    if curl -s --max-time 10 "http://$ALB_DNS/health" > /dev/null; then
        echo "✅ Vulnerable application is responding"
        break
    else
        echo "⏳ Waiting for application to be ready... (attempt $i/10)"
        sleep 30
    fi

    if [ $i -eq 10 ]; then
        echo "❌ Application is not responding after 5 minutes"
        echo "Check the EC2 instances and target group health"
        exit 1
    fi
done

# Show application URL
echo -e "\n🌐 Vulnerable Application URL: http://$ALB_DNS"

# Ask user if they want to deploy WAF protection
echo -e "\n❓ Do you want to deploy WAF protection now? (y/n)"
read -r deploy_waf

if [[ $deploy_waf =~ ^[Yy]$ ]]; then
    echo -e "\n🛡️  Deploying WAF protection..."

    aws cloudformation deploy \
        --template-file "$(dirname "$(pwd)")/cloudformation/02-waf-protection.yaml" \
        --stack-name "${STACK_PREFIX}-waf" \
        --parameter-overrides LoadBalancerArn="$ALB_ARN" \
        --region "$REGION" \
        --tags \
            Purpose="Lightning Talk Demo" \
            Environment="Demo" \
            Owner="$(aws sts get-caller-identity --query 'Arn' --output text)"

    wait_for_stack "${STACK_PREFIX}-waf" "create-or-update"

    # Get WAF Web ACL ID
    WAF_ACL_ID=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_PREFIX}-waf" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`WebACLId`].OutputValue' \
        --output text)

    echo "✅ WAF Web ACL ID: $WAF_ACL_ID"

    # Get dashboard URL
    DASHBOARD_URL=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_PREFIX}-waf" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`DashboardURL`].OutputValue' \
        --output text)

    echo "✅ CloudWatch Dashboard: $DASHBOARD_URL"

    # Get WAF console URL
    WAF_CONSOLE_URL=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_PREFIX}-waf" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`WAFConsoleURL`].OutputValue' \
        --output text)

    echo "✅ WAF Console: $WAF_CONSOLE_URL"
else
    echo "⏭️  Skipping WAF deployment. You can deploy it later using:"
    echo "   aws cloudformation deploy --template-file ../cloudformation/02-waf-protection.yaml --stack-name ${STACK_PREFIX}-waf --parameter-overrides LoadBalancerArn=$ALB_ARN --region $REGION"
fi

# Create demo information file
cat > "../demo-info.txt" << EOF
AWS WAF Lightning Talk Demo - Deployment Information
===================================================

Deployment Date: $(date)
Region: $REGION
Stack Prefix: $STACK_PREFIX

Application Details:
- Application URL: http://$ALB_DNS
- ALB ARN: $ALB_ARN
- Stack Name: ${STACK_PREFIX}-app

WAF Details:
- WAF Stack: ${STACK_PREFIX}-waf
- WAF ACL ID: ${WAF_ACL_ID:-"Not deployed"}

Useful URLs:
- Application: http://$ALB_DNS
- CloudWatch Dashboard: ${DASHBOARD_URL:-"Not available"}
- WAF Console: ${WAF_CONSOLE_URL:-"Not available"}

Test Commands:
==============

# Test normal functionality:
curl http://$ALB_DNS/

# Test SQL injection (should be blocked with WAF):
curl "http://$ALB_DNS/search?q='; DROP TABLE users; --"

# Test XSS (should be blocked with WAF):
curl "http://$ALB_DNS/search?q=<script>alert('XSS')</script>"

# Test brute force (should be rate limited with WAF):
for i in {1..150}; do curl -X POST http://$ALB_DNS/login -d "username=admin&password=test\$i"; done

Attack Simulation Scripts:
=========================
cd attacks/
./run-all-attacks.sh http://$ALB_DNS

Cleanup Commands:
================
aws cloudformation delete-stack --stack-name ${STACK_PREFIX}-waf --region $REGION
aws cloudformation delete-stack --stack-name ${STACK_PREFIX}-app --region $REGION
EOF

echo -e "\n🎉 DEPLOYMENT COMPLETE!"
echo "======================="
echo "📋 Demo information saved to: ../demo-info.txt"
echo "🌐 Application URL: http://$ALB_DNS"
echo "📊 Dashboard: ${DASHBOARD_URL:-"Deploy WAF to get dashboard"}"

echo -e "\n🎯 Next Steps for Your Lightning Talk:"
echo "1. Test the vulnerable application without WAF"
echo "2. Run attack simulations: cd attacks && ./run-all-attacks.sh http://$ALB_DNS"
echo "3. Deploy WAF protection (if not done already)"
echo "4. Run the same attacks to show they're blocked"
echo "5. Show the CloudWatch dashboard with metrics"

echo -e "\n💡 Pro Tips:"
echo "- Keep the demo-info.txt file handy during your talk"
echo "- Pre-run the attacks to ensure they work"
echo "- Have the CloudWatch dashboard open in a browser tab"
echo "- Practice the deployment process beforehand"

echo -e "\n🧹 Cleanup:"
echo "Don't forget to delete the stacks after your demo to avoid charges:"
echo "  ./cleanup-demo.sh $REGION $STACK_PREFIX"
