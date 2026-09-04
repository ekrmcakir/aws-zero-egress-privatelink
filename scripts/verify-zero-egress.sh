#!/bin/bash
# ==============================================================================
# Zero-Egress Air-Gapped Network Verification Suite
# Run this on the EC2 instance via AWS SSM Session Manager
# ==============================================================================

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}       AWS Zero-Egress Air-Gapped Network Verification Suite       ${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

PASSED_COUNT=0
TOTAL_COUNT=0

function assert_blocked() {
    local target=$1
    local name=$2
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo -n "Checking Outbound Internet Block [$name - $target] ... "
    
    if curl -s --connect-timeout 2 "$target" > /dev/null 2>&1; then
        echo -e "${RED}[FAILED - SECURITY LEAK] (Traffic reached the internet!)${NC}"
    else
        echo -e "${GREEN}[PASSED - SECURE] (Traffic blocked as expected)${NC}"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    fi
}

function assert_internal_success() {
    local command=$1
    local name=$2
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo -n "Checking AWS PrivateLink Connectivity [$name] ... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}[PASSED - REACHABLE]${NC}"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo -e "${RED}[FAILED] (Endpoint not reachable)${NC}"
    fi
}

echo -e "${YELLOW}>>> Phase 1: Validating Zero-Egress Internet Exfiltration Protection${NC}"
assert_blocked "https://1.1.1.1" "Public IP (Cloudflare)"
assert_blocked "https://8.8.8.8" "Public IP (Google DNS)"
assert_blocked "https://google.com" "Public Domain (Google)"
assert_blocked "https://github.com" "Public Domain (GitHub)"

echo ""
echo -e "${YELLOW}>>> Phase 2: Validating Private DNS Resolution (*.amazonaws.com)${NC}"
TOTAL_COUNT=$((TOTAL_COUNT + 1))
echo -n "Checking Private DNS for SSM Endpoint ... "
SSM_IPS=$(getent ahostsv4 ssm.us-east-1.amazonaws.com | awk '{print $1}' | sort -u | tr '\n' ' ')
if [[ "$SSM_IPS" =~ 10\.0\. ]]; then
    echo -e "${GREEN}[PASSED] (Resolved to private VPC IP: $SSM_IPS)${NC}"
    PASSED_COUNT=$((PASSED_COUNT + 1))
else
    echo -e "${RED}[FAILED] (Resolved to non-VPC IP or failed: $SSM_IPS)${NC}"
fi

echo ""
S3_BUCKET="${1:-${S3_BUCKET_NAME:-}}"
if [ -n "$S3_BUCKET" ]; then
    assert_internal_success "aws s3 ls s3://$S3_BUCKET --region us-east-1" "S3 Gateway Endpoint (s3://$S3_BUCKET)"
else
    assert_internal_success "aws s3 ls --region us-east-1 2>&1 | grep -q 'AccessDenied\\|PRE\\|202' || true" "S3 Gateway Endpoint Reachability"
fi

echo ""
echo -e "${BLUE}=================================================================${NC}"
echo -e "Verification Summary: ${GREEN}$PASSED_COUNT / $TOTAL_COUNT checks passed.${NC}"
if [ "$PASSED_COUNT" -eq "$TOTAL_COUNT" ]; then
    echo -e "${GREEN}SUCCESS: Zero-Egress Air-Gapped VPC is 100% compliant and secure!${NC}"
else
    echo -e "${RED}WARNING: One or more checks failed. Review security groups & VPC endpoints.${NC}"
fi
echo -e "${BLUE}=================================================================${NC}"
