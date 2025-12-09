#!/bin/bash

# AWS Profile Helper
# This script sets up AWS profile support for all scripts
# Usage: source scripts/aws-profile.sh [profile-name]

# Set AWS_PROFILE if provided as argument
if [ -n "$1" ]; then
    export AWS_PROFILE="$1"
    echo "✓ Using AWS profile: ${AWS_PROFILE}"
elif [ -n "${AWS_PROFILE}" ]; then
    echo "✓ Using AWS profile from environment: ${AWS_PROFILE}"
else
    echo "ℹ️  No AWS profile specified, using default credentials"
fi

# Helper function to build AWS CLI command with profile
aws_cmd() {
    if [ -n "${AWS_PROFILE}" ]; then
        aws --profile "${AWS_PROFILE}" "$@"
    else
        aws "$@"
    fi
}

# Export the function so it's available in subshells
export -f aws_cmd

# Set AWS_CLI_ARGS for use in scripts
if [ -n "${AWS_PROFILE}" ]; then
    export AWS_CLI_ARGS="--profile ${AWS_PROFILE}"
else
    export AWS_CLI_ARGS=""
fi

echo "AWS_CLI_ARGS=${AWS_CLI_ARGS}"
