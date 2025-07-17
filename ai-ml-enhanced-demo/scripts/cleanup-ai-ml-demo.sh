#!/bin/bash

# AWS WAF AI/ML Enhanced Demo Cleanup Script
# Removes all resources created by the demo

set -e

REGION=${1:-"us-east-1"}
ENVIRONMENT=${2:-"ai-ml-demo"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 AWS WAF AI/ML Enhanced Demo Cleanup${NC}"
echo "======================================"
echo "Region: $REGION"
echo "Environment: $ENVIRONMENT"
echo "======================================"

# Confirmation prompt
echo -e "${YELLOW}⚠️  This will delete ALL resources for the $ENVIRONMENT demo${NC}"
echo "Stacks to be deleted:"
echo "  - ${ENVIRONMENT}-waf"
echo "  - ${ENVIRONMENT}-app"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo -e "${BLUE}❌ Cleanup cancelled${NC}"
    exit 0
fi

echo -e "\n${BLUE}🗑️  Starting cleanup process...${NC}"

# Function to wait for stack deletion
wait_for_stack_deletion() {
    local stack_name="$1"
    echo -e "${YELLOW}⏳ Waiting for stack $stack_name to be deleted...${NC}"
    
    while true; do
        status=$(aws cloudformation describe-stacks \
            --stack-name "$stack_name" \
            --region "$REGION" \
            --query 'Stacks[0].StackStatus' \
            --output text 2>/dev/null || echo "STACK_NOT_FOUND")
        
        if [[ "$status" == "STACK_NOT_FOUND" ]]; then
            echo -e "${GREEN}✅ Stack $stack_name deleted successfully${NC}"
            break
        elif [[ "$status" == "DELETE_FAILED" ]]; then
            echo -e "${RED}❌ Stack $stack_name deletion failed${NC}"
            break
        else
            echo -n "."
            sleep 10
        fi
    done
}

# Step 1: Delete WAF Stack (must be first to disassociate from ALB)
echo -e "\n${BLUE}🛡️  Step 1: Deleting WAF Stack${NC}"
if aws cloudformation describe-stacks --stack-name "${ENVIRONMENT}-waf" --region "$REGION" > /dev/null 2>&1; then
    aws cloudformation delete-stack \
        --stack-name "${ENVIRONMENT}-waf" \
        --region "$REGION"
    
    wait_for_stack_deletion "${ENVIRONMENT}-waf"
else
    echo -e "${YELLOW}⚠️  WAF stack ${ENVIRONMENT}-waf not found${NC}"
fi

# Step 2: Delete Application Stack
echo -e "\n${BLUE}📦 Step 2: Deleting Application Stack${NC}"
if aws cloudformation describe-stacks --stack-name "${ENVIRONMENT}-app" --region "$REGION" > /dev/null 2>&1; then
    aws cloudformation delete-stack \
        --stack-name "${ENVIRONMENT}-app" \
        --region "$REGION"
    
    wait_for_stack_deletion "${ENVIRONMENT}-app"
else
    echo -e "${YELLOW}⚠️  Application stack ${ENVIRONMENT}-app not found${NC}"
fi

# Step 3: Clean up any remaining resources (safety check)
echo -e "\n${BLUE}🔍 Step 3: Checking for remaining resources${NC}"

# Check for any remaining WAF Web ACLs
echo "Checking for orphaned WAF Web ACLs..."
WAF_ACLS=$(aws wafv2 list-web-acls \
    --scope REGIONAL \
    --region "$REGION" \
    --query "WebACLs[?contains(Name, '$ENVIRONMENT')].{Name:Name,Id:Id}" \
    --output text 2>/dev/null || echo "")

if [[ -n "$WAF_ACLS" ]]; then
    echo -e "${YELLOW}⚠️  Found orphaned WAF Web ACLs:${NC}"
    echo "$WAF_ACLS"
    echo "These may need manual cleanup if they weren't properly deleted."
else
    echo -e "${GREEN}✅ No orphaned WAF Web ACLs found${NC}"
fi

# Check for any remaining Load Balancers
echo "Checking for orphaned Load Balancers..."
ALBS=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, '$ENVIRONMENT')].{Name:LoadBalancerName,Arn:LoadBalancerArn}" \
    --output text 2>/dev/null || echo "")

if [[ -n "$ALBS" ]]; then
    echo -e "${YELLOW}⚠️  Found orphaned Load Balancers:${NC}"
    echo "$ALBS"
    echo "These may need manual cleanup if they weren't properly deleted."
else
    echo -e "${GREEN}✅ No orphaned Load Balancers found${NC}"
fi

# Step 4: Clean up local temporary files
echo -e "\n${BLUE}🗂️  Step 4: Cleaning up local files${NC}"

# Remove temporary files
rm -f /tmp/${ENVIRONMENT}-*.json
rm -f /tmp/*_response*.txt
rm -f /tmp/baseline_*.txt
rm -f /tmp/ml_*.txt
rm -f /tmp/learning_*.txt
rm -f /tmp/behavioral_*.txt

echo -e "${GREEN}✅ Local temporary files cleaned up${NC}"

# Step 5: Display cleanup summary
echo -e "\n${GREEN}🎉 Cleanup Complete!${NC}"
echo "==================="
echo -e "${BLUE}📊 Cleanup Summary:${NC}"
echo "  Environment: $ENVIRONMENT"
echo "  Region: $REGION"
echo "  Stacks deleted:"
echo "    - ${ENVIRONMENT}-waf"
echo "    - ${ENVIRONMENT}-app"
echo "  Local files cleaned up"
echo ""
echo -e "${BLUE}💰 Cost Impact:${NC}"
echo "  All AWS resources have been deleted"
echo "  No further charges should occur for this demo"
echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo "  - Verify in AWS Console that all resources are deleted"
echo "  - Check your AWS bill to confirm no ongoing charges"
echo "  - Re-run deployment script if you want to recreate the demo"
echo ""

# Check if there were any issues
if aws cloudformation describe-stacks --stack-name "${ENVIRONMENT}-waf" --region "$REGION" > /dev/null 2>&1 || \
   aws cloudformation describe-stacks --stack-name "${ENVIRONMENT}-app" --region "$REGION" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Warning: Some stacks may still exist${NC}"
    echo "Please check the AWS CloudFormation console for any remaining stacks"
    echo "Manual cleanup may be required if deletion failed"
else
    echo -e "${GREEN}✅ All demo resources successfully cleaned up!${NC}"
fi

echo -e "\n${BLUE}Thank you for using the AWS WAF AI/ML Enhanced Demo! 🚀${NC}"
