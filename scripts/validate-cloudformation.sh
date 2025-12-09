#!/bin/bash

# Script to validate CloudFormation templates
# Usage: ./validate-cloudformation.sh

set -e

echo "✅ Validating CloudFormation templates..."
echo ""

AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_REGION=${AWS_REGION:-us-east-1}

TEMPLATES=(
    "infrastructure/cloudformation/ecr-repositories.yaml"
    "infrastructure/cloudformation/sns-sqs.yaml"
    "infrastructure/cloudformation/eks-cluster.yaml"
)

ERRORS=0

for TEMPLATE in "${TEMPLATES[@]}"; do
    echo -n "Validating $(basename ${TEMPLATE})... "
    
    if aws cloudformation validate-template \
        --template-body file://${TEMPLATE} \
        --region "${AWS_REGION}" \
        &> /dev/null; then
        echo "✓"
    else
        echo "✗"
        echo "  Error in ${TEMPLATE}"
        ((ERRORS++))
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All templates are valid!"
    exit 0
else
    echo "❌ Found ${ERRORS} invalid template(s)"
    exit 1
fi
