#!/bin/bash

# Script to verify all prerequisites are installed
# Usage: ./verify-prerequisites.sh [--profile PROFILE_NAME]

set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--profile PROFILE_NAME]"
      exit 1
      ;;
  esac
done

# Set AWS CLI arguments
if [ -n "${AWS_PROFILE}" ]; then
    AWS_CLI_ARGS="--profile ${AWS_PROFILE}"
    echo "Using AWS profile: ${AWS_PROFILE}"
else
    AWS_CLI_ARGS=""
fi

echo "🔍 Verifying prerequisites..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Check AWS CLI
echo -n "Checking AWS CLI... "
if command -v aws &> /dev/null; then
    VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    echo -e "${GREEN}✓ Installed (${VERSION})${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://aws.amazon.com/cli/"
    ((ERRORS++))
fi

# Check Docker
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo -e "${GREEN}✓ Installed (${VERSION})${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://docs.docker.com/get-docker/"
    ((ERRORS++))
fi

# Check kubectl
echo -n "Checking kubectl... "
if command -v kubectl &> /dev/null; then
    VERSION=$(kubectl version --client --short 2>&1 | grep -oP 'v\d+\.\d+\.\d+' | head -1)
    echo -e "${GREEN}✓ Installed (${VERSION})${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://kubernetes.io/docs/tasks/tools/"
    ((ERRORS++))
fi

# Check eksctl
echo -n "Checking eksctl... "
if command -v eksctl &> /dev/null; then
    VERSION=$(eksctl version)
    echo -e "${GREEN}✓ Installed (${VERSION})${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://eksctl.io/introduction/#installation"
    ((ERRORS++))
fi

# Check Helm
echo -n "Checking Helm... "
if command -v helm &> /dev/null; then
    VERSION=$(helm version --short | cut -d':' -f2 | tr -d ' ')
    echo -e "${GREEN}✓ Installed (${VERSION})${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://helm.sh/docs/intro/install/"
    ((ERRORS++))
fi

# Check Node.js
echo -n "Checking Node.js... "
if command -v node &> /dev/null; then
    VERSION=$(node --version)
    echo -e "${GREEN}✓ Installed (${VERSION})${NC}"
    
    # Check if version is >= 20
    MAJOR_VERSION=$(node --version | cut -d'.' -f1 | tr -d 'v')
    if [ "$MAJOR_VERSION" -lt 20 ]; then
        echo -e "${YELLOW}  ⚠ Warning: Node.js 20.x or higher is recommended${NC}"
    fi
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install: https://nodejs.org/"
    ((ERRORS++))
fi

# Check TypeScript
echo -n "Checking TypeScript... "
if command -v tsc &> /dev/null; then
    VERSION=$(tsc --version | cut -d' ' -f2)
    echo -e "${GREEN}✓ Installed (${VERSION})${NC}"
else
    echo -e "${YELLOW}⚠ Not installed globally${NC}"
    echo "  Install: npm install -g typescript"
fi

# Check AWS credentials
echo -n "Checking AWS credentials... "
if aws sts get-caller-identity ${AWS_CLI_ARGS} &> /dev/null; then
    ACCOUNT=$(aws sts get-caller-identity ${AWS_CLI_ARGS} --query Account --output text)
    REGION=$(aws configure get region ${AWS_CLI_ARGS} || echo "not-set")
    echo -e "${GREEN}✓ Configured${NC}"
    echo "  Account: ${ACCOUNT}"
    echo "  Region: ${REGION}"
    if [ -n "${AWS_PROFILE}" ]; then
        echo "  Profile: ${AWS_PROFILE}"
    fi
else
    echo -e "${RED}✗ Not configured${NC}"
    echo "  Run: aws configure"
    if [ -n "${AWS_PROFILE}" ]; then
        echo "  Or: aws configure --profile ${AWS_PROFILE}"
    fi
    ((ERRORS++))
fi

echo ""
echo "========================================"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All prerequisites verified!${NC}"
    exit 0
else
    echo -e "${RED}✗ Found ${ERRORS} missing prerequisite(s)${NC}"
    echo "Please install the missing tools and try again."
    exit 1
fi
