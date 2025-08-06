#!/bin/bash

# Comprehensive Attack Simulation for AWS WAF Demo
# Usage: ./run-all-attacks.sh <target-url>

TARGET_URL=${1:-"http://localhost:3000"}

echo "🚨 COMPREHENSIVE SECURITY TESTING"
echo "=================================="
echo "Target: $TARGET_URL"
echo "Time: $(date)"
echo "=================================="

# Check if target is reachable
echo "Checking target availability..."
if ! curl -s --max-time 5 "$TARGET_URL/health" > /dev/null; then
    echo "❌ Target is not reachable. Please check the URL and try again."
    exit 1
fi
echo "✅ Target is reachable"

# Create results directory
RESULTS_DIR="attack-results-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESULTS_DIR"

echo -e "\n📊 Results will be saved to: $RESULTS_DIR"

# Function to run attack and capture results
run_attack() {
    local attack_name="$1"
    local script_name="$2"
    local description="$3"

    echo -e "\n🎯 Running $attack_name"
    echo "Description: $description"
    echo "----------------------------------------"

    if [ -f "$script_name" ]; then
        chmod +x "$script_name"
        ./"$script_name" "$TARGET_URL" | tee "$RESULTS_DIR/${attack_name,,}-results.txt"
    else
        echo "❌ Script $script_name not found"
    fi

    echo "----------------------------------------"
    sleep 2
}

# 1. SQL Injection Attacks
run_attack "SQL-Injection" "sql-injection-test.sh" "Testing various SQL injection techniques"

# 2. XSS Attacks
run_attack "XSS-Attacks" "xss-test.sh" "Testing cross-site scripting vulnerabilities"

# 3. Brute Force Attacks
# run_attack "Brute-Force" "brute-force-test.sh" "Testing rate limiting and login protection"

# 3. Brute Enhanced Attacks
# run_attack "AI Enhanced" "ai-ml-enhanced-attacks.sh" "Testing Enhanced AI/ML based attacks"

# 4. Additional manual tests
echo -e "\n🔧 Running Additional Security Tests..."

# Test 4: Directory traversal
echo -e "\n4. Testing Directory Traversal..."
curl -s "$TARGET_URL/search?q=../../../etc/passwd" | head -5
curl -s "$TARGET_URL/search?q=....//....//....//etc/passwd" | head -5

# Test 5: Command injection
echo -e "\n5. Testing Command Injection..."
curl -s "$TARGET_URL/search?q=; ls -la" | head -5
curl -s "$TARGET_URL/search?q=| whoami" | head -5

# Test 6: HTTP header injection
echo -e "\n6. Testing HTTP Header Injection..."
curl -s -H "X-Forwarded-For: <script>alert('XSS')</script>" "$TARGET_URL/" | head -5
curl -s -H "User-Agent: <script>alert('XSS')</script>" "$TARGET_URL/" | head -5

# Test 7: Large payload (DoS attempt)
echo -e "\n7. Testing Large Payload Handling..."
large_payload=$(python3 -c "print('A' * 10000)" 2>/dev/null || echo "AAAAAAAAAA")
curl -s --max-time 5 -X POST "$TARGET_URL/comment" -d "comment=$large_payload" | head -5

# Test 8: Malformed requests
echo -e "\n8. Testing Malformed Requests..."
curl -s --max-time 5 "$TARGET_URL/search?q=%00%00%00" | head -5
curl -s --max-time 5 "$TARGET_URL/search?q=%FF%FE%FD" | head -5

# Check WAF status if possible
echo -e "\n🔍 Checking WAF Protection Status..."
if command -v aws &> /dev/null; then
    echo "AWS CLI detected - checking WAF configuration..."
    # This would require proper AWS credentials and WebACL ID
    # aws wafv2 get-web-acl --scope REGIONAL --id <web-acl-id> --region <region>
    echo "Note: Manual WAF check required via AWS Console"
else
    echo "AWS CLI not available - check WAF status manually in AWS Console"
fi

# Final summary
echo -e "\n🎉 TESTING COMPLETE!"
echo "=================================="
echo "📁 Results saved to: $RESULTS_DIR"
echo "🕒 Completed at: $(date)"

# Display quick stats
total_files=$(ls -1 "$RESULTS_DIR"/*.txt 2>/dev/null | wc -l)
echo "📈 Generated $total_files detailed result files"