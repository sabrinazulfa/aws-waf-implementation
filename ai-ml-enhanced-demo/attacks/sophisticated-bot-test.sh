#!/bin/bash

# Sophisticated Bot Attack Simulation for AI/ML WAF Testing
# This script simulates advanced bot behaviors that traditional rules might miss

set -e

TARGET_URL=${1:-"http://localhost:3000"}
ATTACK_TYPE=${2:-"all"}
VERBOSE=${3:-"false"}

echo "🤖 Starting Sophisticated Bot Attack Simulation"
echo "Target: $TARGET_URL"
echo "Attack Type: $ATTACK_TYPE"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log results
log_result() {
    local test_name="$1"
    local status_code="$2"
    local response="$3"
    
    if [[ $status_code -eq 200 ]]; then
        echo -e "${GREEN}✓ $test_name: SUCCESS (Status: $status_code)${NC}"
    elif [[ $status_code -eq 403 ]]; then
        echo -e "${RED}✗ $test_name: BLOCKED by WAF (Status: $status_code)${NC}"
    elif [[ $status_code -eq 429 ]]; then
        echo -e "${YELLOW}⚠ $test_name: RATE LIMITED (Status: $status_code)${NC}"
    else
        echo -e "${BLUE}? $test_name: UNEXPECTED (Status: $status_code)${NC}"
    fi
    
    if [[ $VERBOSE == "true" ]]; then
        echo "Response: $response"
        echo "---"
    fi
}

# Test 1: Human-like Bot Simulation
test_human_like_bot() {
    echo -e "\n${BLUE}Test 1: Human-like Bot Behavior${NC}"
    
    # Simulate realistic user agent and headers
    USER_AGENTS=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    )
    
    for i in {1..5}; do
        USER_AGENT=${USER_AGENTS[$((RANDOM % ${#USER_AGENTS[@]}))]}
        
        response=$(curl -s -w "%{http_code}" -o /tmp/bot_response_$i.txt \
            -H "User-Agent: $USER_AGENT" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
            -H "Accept-Language: en-US,en;q=0.5" \
            -H "Accept-Encoding: gzip, deflate" \
            -H "Connection: keep-alive" \
            -H "Upgrade-Insecure-Requests: 1" \
            "$TARGET_URL/api/bot-challenge")
        
        log_result "Human-like Bot Request $i" "$response" "$(cat /tmp/bot_response_$i.txt)"
        
        # Random delay to simulate human behavior
        sleep $((RANDOM % 3 + 1))
    done
}

# Test 2: Headless Browser Simulation
test_headless_browser_bot() {
    echo -e "\n${BLUE}Test 2: Headless Browser Bot${NC}"
    
    # Simulate headless Chrome/Firefox
    HEADLESS_AGENTS=(
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/91.0.4472.124 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0"
    )
    
    for agent in "${HEADLESS_AGENTS[@]}"; do
        response=$(curl -s -w "%{http_code}" -o /tmp/headless_response.txt \
            -H "User-Agent: $agent" \
            -H "Accept: */*" \
            "$TARGET_URL/api/bot-challenge")
        
        log_result "Headless Browser Bot" "$response" "$(cat /tmp/headless_response.txt)"
        sleep 2
    done
}

# Test 3: API Bot with Realistic Patterns
test_api_bot() {
    echo -e "\n${BLUE}Test 3: API Bot with Realistic Patterns${NC}"
    
    # Simulate legitimate API client behavior
    for i in {1..10}; do
        response=$(curl -s -w "%{http_code}" -o /tmp/api_response_$i.txt \
            -H "User-Agent: MyApp/1.0 (API Client)" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            "$TARGET_URL/api/analytics")
        
        log_result "API Bot Request $i" "$response" "$(cat /tmp/api_response_$i.txt)"
        
        # Realistic API call intervals
        sleep 0.5
    done
}

# Test 4: Distributed Bot Attack
test_distributed_bot() {
    echo -e "\n${BLUE}Test 4: Distributed Bot Attack${NC}"
    
    # Simulate requests from different "IP addresses" (using different source ports)
    for i in {1..20}; do
        response=$(curl -s -w "%{http_code}" -o /tmp/distributed_response_$i.txt \
            --local-port $((8000 + i)) \
            -H "User-Agent: DistributedBot/$i" \
            -H "X-Forwarded-For: 192.168.$((RANDOM % 255)).$((RANDOM % 255))" \
            "$TARGET_URL/search?q=test$i")
        
        log_result "Distributed Bot $i" "$response" "$(cat /tmp/distributed_response_$i.txt)"
        
        # Fast requests to trigger rate limiting
        sleep 0.1
    done
}

# Test 5: Behavioral Evasion Bot
test_behavioral_evasion() {
    echo -e "\n${BLUE}Test 5: Behavioral Evasion Bot${NC}"
    
    # Try to evade behavioral analysis
    response=$(curl -s -w "%{http_code}" -o /tmp/behavioral_response.txt \
        -X POST \
        -H "Content-Type: application/json" \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        -d '{
            "mouseMovements": [],
            "keystrokes": 0,
            "timeOnPage": 100
        }' \
        "$TARGET_URL/api/behavioral-analysis")
    
    log_result "Behavioral Evasion Bot" "$response" "$(cat /tmp/behavioral_response.txt)"
}

# Test 6: Machine Learning Evasion Attempts
test_ml_evasion() {
    echo -e "\n${BLUE}Test 6: ML Evasion Attempts${NC}"
    
    # Try various techniques to evade ML detection
    EVASION_TECHNIQUES=(
        "slow-requests"
        "header-randomization"
        "payload-obfuscation"
        "timing-variation"
    )
    
    for technique in "${EVASION_TECHNIQUES[@]}"; do
        case $technique in
            "slow-requests")
                response=$(curl -s -w "%{http_code}" -o /tmp/evasion_slow.txt \
                    --limit-rate 1k \
                    -H "User-Agent: SlowBot/1.0" \
                    "$TARGET_URL/api/bot-challenge")
                log_result "ML Evasion: Slow Requests" "$response" "$(cat /tmp/evasion_slow.txt)"
                ;;
            "header-randomization")
                response=$(curl -s -w "%{http_code}" -o /tmp/evasion_headers.txt \
                    -H "User-Agent: RandomBot-$RANDOM" \
                    -H "X-Random-Header: $RANDOM" \
                    -H "X-Custom-Field: evasion-$RANDOM" \
                    "$TARGET_URL/api/bot-challenge")
                log_result "ML Evasion: Header Randomization" "$response" "$(cat /tmp/evasion_headers.txt)"
                ;;
            "payload-obfuscation")
                response=$(curl -s -w "%{http_code}" -o /tmp/evasion_payload.txt \
                    -X POST \
                    -H "Content-Type: application/json" \
                    -d "{\"query\": \"$(echo 'test' | base64)\"}" \
                    "$TARGET_URL/search")
                log_result "ML Evasion: Payload Obfuscation" "$response" "$(cat /tmp/evasion_payload.txt)"
                ;;
            "timing-variation")
                for j in {1..5}; do
                    response=$(curl -s -w "%{http_code}" -o /tmp/evasion_timing_$j.txt \
                        -H "User-Agent: TimingBot/$j" \
                        "$TARGET_URL/api/bot-challenge")
                    log_result "ML Evasion: Timing Variation $j" "$response" "$(cat /tmp/evasion_timing_$j.txt)"
                    sleep $((RANDOM % 10 + 1))
                done
                ;;
        esac
    done
}

# Test 7: Advanced Credential Stuffing Bot
test_credential_stuffing_bot() {
    echo -e "\n${BLUE}Test 7: Advanced Credential Stuffing Bot${NC}"
    
    # Common username/password combinations
    CREDENTIALS=(
        "admin:password"
        "admin:123456"
        "user:password"
        "test:test"
        "admin:admin"
        "root:root"
        "user1:qwerty"
        "demo:demo"
    )
    
    for cred in "${CREDENTIALS[@]}"; do
        IFS=':' read -r username password <<< "$cred"
        
        response=$(curl -s -w "%{http_code}" -o /tmp/cred_stuff_response.txt \
            -X POST \
            -H "Content-Type: application/json" \
            -H "User-Agent: CredentialBot/2.0" \
            -d "{\"username\": \"$username\", \"password\": \"$password\"}" \
            "$TARGET_URL/api/login-attempt")
        
        log_result "Credential Stuffing: $username:$password" "$response" "$(cat /tmp/cred_stuff_response.txt)"
        
        # Realistic delay between attempts
        sleep 1
    done
}

# Test 8: Fraud Transaction Bot
test_fraud_transaction_bot() {
    echo -e "\n${BLUE}Test 8: Fraud Transaction Bot${NC}"
    
    # Suspicious transaction patterns
    FRAUD_TRANSACTIONS=(
        '{"amount": 9999, "card_number": "4111111111111111", "merchant": "SuspiciousMerchant"}'
        '{"amount": 1, "card_number": "4000000000000002", "merchant": "TestMerchant"}'
        '{"amount": 5000, "card_number": "4242424242424242", "merchant": "HighRiskMerchant"}'
    )
    
    for transaction in "${FRAUD_TRANSACTIONS[@]}"; do
        response=$(curl -s -w "%{http_code}" -o /tmp/fraud_response.txt \
            -X POST \
            -H "Content-Type: application/json" \
            -H "User-Agent: FraudBot/1.0" \
            -d "$transaction" \
            "$TARGET_URL/api/transaction")
        
        log_result "Fraud Transaction Bot" "$response" "$(cat /tmp/fraud_response.txt)"
        sleep 2
    done
}

# Main execution logic
main() {
    case $ATTACK_TYPE in
        "human-like")
            test_human_like_bot
            ;;
        "headless")
            test_headless_browser_bot
            ;;
        "api")
            test_api_bot
            ;;
        "distributed")
            test_distributed_bot
            ;;
        "behavioral")
            test_behavioral_evasion
            ;;
        "ml-evasion")
            test_ml_evasion
            ;;
        "credential-stuffing")
            test_credential_stuffing_bot
            ;;
        "fraud")
            test_fraud_transaction_bot
            ;;
        "all")
            test_human_like_bot
            test_headless_browser_bot
            test_api_bot
            test_distributed_bot
            test_behavioral_evasion
            test_ml_evasion
            test_credential_stuffing_bot
            test_fraud_transaction_bot
            ;;
        *)
            echo "Unknown attack type: $ATTACK_TYPE"
            echo "Available types: human-like, headless, api, distributed, behavioral, ml-evasion, credential-stuffing, fraud, all"
            exit 1
            ;;
    esac
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
    rm -f /tmp/*_response*.txt
}

# Set trap for cleanup
trap cleanup EXIT

# Run the tests
main

echo -e "\n${GREEN}🤖 Sophisticated Bot Attack Simulation Complete!${NC}"
echo -e "${BLUE}Check your WAF dashboard to see how AI/ML detection performed.${NC}"
