#!/bin/bash

# Brute Force Attack Simulation Script
# Usage: ./brute-force-test.sh <target-url> [number-of-attempts]

TARGET_URL=${1:-"http://localhost:3000"}
ATTEMPTS=${2:-150}

echo "🚨 Brute Force Attack Simulation"
echo "Target: $TARGET_URL"
echo "Attempts: $ATTEMPTS"
echo "=================================="

# Common passwords list
passwords=(
    "password"
    "123456"
    "admin"
    "password123"
    "admin123"
    "root"
    "qwerty"
    "letmein"
    "welcome"
    "monkey"
    "dragon"
    "master"
    "shadow"
    "superman"
    "michael"
    "football"
    "baseball"
    "liverpool"
    "jordan"
    "princess"
)

usernames=(
    "admin"
    "administrator"
    "root"
    "user"
    "test"
    "guest"
    "demo"
)

echo "Starting brute force attack..."
echo "Time: $(date)"

successful_attempts=0
blocked_attempts=0
failed_attempts=0

for ((i=1; i<=ATTEMPTS; i++)); do
    # Select random username and password
    username=${usernames[$((RANDOM % ${#usernames[@]}))]}
    password=${passwords[$((RANDOM % ${#passwords[@]}))]}$i
    
    # Make the request
    response=$(curl -s -w "%{http_code}" -X POST "$TARGET_URL/login" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$username&password=$password" \
        --max-time 5)
    
    http_code="${response: -3}"
    
    case $http_code in
        200)
            echo "✅ SUCCESS: $username:$password (attempt $i)"
            ((successful_attempts++))
            ;;
        401)
            echo "❌ FAILED: $username:$password (attempt $i)"
            ((failed_attempts++))
            ;;
        403|429)
            echo "🚫 BLOCKED: Rate limited or WAF blocked (attempt $i)"
            ((blocked_attempts++))
            ;;
        000)
            echo "⏰ TIMEOUT: Request timed out (attempt $i)"
            ;;
        *)
            echo "❓ UNKNOWN: HTTP $http_code for $username:$password (attempt $i)"
            ;;
    esac
    
    # Progress indicator
    if [ $((i % 10)) -eq 0 ]; then
        echo "Progress: $i/$ATTEMPTS attempts completed..."
    fi
    
    # Small delay to make the attack more realistic
    sleep 0.1
done

echo -e "\n=================================="
echo "Brute Force Attack Summary:"
echo "Total attempts: $ATTEMPTS"
echo "Successful logins: $successful_attempts"
echo "Failed attempts: $failed_attempts"
echo "Blocked attempts: $blocked_attempts"
echo "Completion time: $(date)"

if [ $blocked_attempts -gt 0 ]; then
    echo -e "\n🛡️  WAF Protection Working!"
    echo "Rate limiting successfully blocked $blocked_attempts requests"
else
    echo -e "\n⚠️  No rate limiting detected"
    echo "Consider enabling WAF protection"
fi
