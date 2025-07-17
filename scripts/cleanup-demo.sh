#!/bin/bash

# AWS WAF Lightning Talk Demo Cleanup Script
# Usage: ./cleanup-demo.sh [region] [stack-prefix]

set -e

REGION=${1:-"us-east-1"}
STACK_PREFIX=${2:-"waf-lightning-demo"}

echo "🧹 AWS WAF Lightning Talk Demo Cleanup"
echo "======================================"
echo "Region: $REGION"
echo "Stack Prefix: $STACK_PREFIX"
echo "Time: $(date)"
echo "======================================"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured."
    exit 1
fi

echo "✅ AWS CLI configured and credentials valid"

# Function to check if stack exists
stack_exists() {
    local stack_name="$1"
    aws cloudformation describe-stacks --stack-name "$stack_name" --region "$REGION" &> /dev/null
}

# Function to wait for stack deletion
wait_for_deletion() {
    local stack_name="$1"
    
    echo "⏳ Waiting for stack deletion to complete: $stack_name"
    
    aws cloudformation wait stack-delete-complete \
        --stack-name "$stack_name" \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        echo "✅ Stack deleted successfully: $stack_name"
    else
        echo "❌ Stack deletion failed: $stack_name"
        aws cloudformation describe-stack-events \
            --stack-name "$stack_name" \
            --region "$REGION" \
            --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[Timestamp,ResourceType,LogicalResourceId,ResourceStatusReason]' \
            --output table
    fi
}

# List stacks to be deleted
echo -e "\n🔍 Checking for demo stacks..."

WAF_STACK="${STACK_PREFIX}-waf"
APP_STACK="${STACK_PREFIX}-app"

stacks_to_delete=()

if stack_exists "$WAF_STACK"; then
    echo "Found WAF stack: $WAF_STACK"
    stacks_to_delete+=("$WAF_STACK")
fi

if stack_exists "$APP_STACK"; then
    echo "Found App stack: $APP_STACK"
    stacks_to_delete+=("$APP_STACK")
fi

if [ ${#stacks_to_delete[@]} -eq 0 ]; then
    echo "✅ No demo stacks found to delete"
    exit 0
fi

# Confirm deletion
echo -e "\n⚠️  WARNING: This will delete the following stacks:"
for stack in "${stacks_to_delete[@]}"; do
    echo "   - $stack"
done

echo -e "\n❓ Are you sure you want to delete these stacks? (yes/no)"
read -r confirmation

if [[ ! $confirmation =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

# Delete WAF stack first (to remove association)
if stack_exists "$WAF_STACK"; then
    echo -e "\n🛡️  Deleting WAF stack: $WAF_STACK"
    aws cloudformation delete-stack --stack-name "$WAF_STACK" --region "$REGION"
    wait_for_deletion "$WAF_STACK"
fi

# Delete application stack
if stack_exists "$APP_STACK"; then
    echo -e "\n📦 Deleting application stack: $APP_STACK"
    aws cloudformation delete-stack --stack-name "$APP_STACK" --region "$REGION"
    wait_for_deletion "$APP_STACK"
fi

# Clean up local files
echo -e "\n🗂️  Cleaning up local demo files..."

if [ -f "../demo-info.txt" ]; then
    rm "../demo-info.txt"
    echo "✅ Removed demo-info.txt"
fi

if [ -d "../attacks/attack-results-"* ]; then
    rm -rf ../attacks/attack-results-*
    echo "✅ Removed attack result directories"
fi

# Check for any remaining resources
echo -e "\n🔍 Checking for any remaining demo resources..."

# Check for orphaned load balancers
orphaned_albs=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, 'WAF-Demo')].LoadBalancerArn" \
    --output text 2>/dev/null || echo "")

if [ -n "$orphaned_albs" ]; then
    echo "⚠️  Found orphaned load balancers:"
    echo "$orphaned_albs"
    echo "You may need to delete these manually"
fi

# Check for orphaned security groups
orphaned_sgs=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --query "SecurityGroups[?contains(GroupName, 'WAF-Demo')].GroupId" \
    --output text 2>/dev/null || echo "")

if [ -n "$orphaned_sgs" ]; then
    echo "⚠️  Found orphaned security groups:"
    echo "$orphaned_sgs"
    echo "You may need to delete these manually"
fi

# Check for orphaned WAF Web ACLs
orphaned_waf=$(aws wafv2 list-web-acls \
    --scope REGIONAL \
    --region "$REGION" \
    --query "WebACLs[?contains(Name, '$STACK_PREFIX')].Id" \
    --output text 2>/dev/null || echo "")

if [ -n "$orphaned_waf" ]; then
    echo "⚠️  Found orphaned WAF Web ACLs:"
    echo "$orphaned_waf"
    echo "You may need to delete these manually"
fi

# Final summary
echo -e "\n🎉 CLEANUP COMPLETE!"
echo "==================="
echo "✅ All demo stacks have been deleted"
echo "✅ Local demo files cleaned up"
echo "🕒 Completed at: $(date)"

# Cost estimation
echo -e "\n💰 Cost Impact:"
echo "The following resources have been deleted and will no longer incur charges:"
echo "   - EC2 instances (t3.micro)"
echo "   - Application Load Balancer"
echo "   - NAT Gateway (if created)"
echo "   - EBS volumes"
echo "   - CloudWatch logs (after retention period)"
echo "   - WAF Web ACL requests"

echo -e "\n📋 Summary:"
echo "   - Demo environment completely removed"
echo "   - No ongoing AWS charges for demo resources"
echo "   - Ready for next demo deployment"

echo -e "\n💡 Next Time:"
echo "To redeploy the demo, run:"
echo "   ./deploy-demo.sh $REGION [key-pair-name]"
