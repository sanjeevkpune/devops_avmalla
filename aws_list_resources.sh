#!/bin/bash

###############################################################################
# aws_list_resources.sh
#
# Description:
#   This script lists AWS resources for a specified region and service.
#   It supports the top 15 most widely used AWS services, including EC2, S3,
#   Lambda, RDS, DynamoDB, CloudFormation, CloudWatch, SNS, SQS, IAM,
#   ElastiCache, EKS, ECR, ELB, and KMS.
#
# Usage:
#   ./aws_list_resources.sh <aws-region> <aws-service>
#
#   Example:
#     ./aws_list_resources.sh us-east-1 ec2
#
# Features:
#   - Validates that both region and service arguments are provided.
#   - Checks if AWS CLI is installed.
#   - Checks if AWS CLI is configured.
#   - Validates that the requested service is supported.
#   - Lists resources for the specified service in the given region.
#
# Supported Services:
#   ec2, s3, lambda, rds, dynamodb, cloudformation, cloudwatch,
#   sns, sqs, iam, elasticache, eks, ecr, elb, kms
#
# Requirements:
#   - AWS CLI must be installed and configured.
#
# Author:
#   Veeramalla Abhi (based on user requirements)
###############################################################################


# Top 15 AWS services supported
SERVICES=("ec2" "s3" "lambda" "rds" "dynamodb" "cloudformation" "cloudwatch" "sns" "sqs" "iam" "elasticache" "eks" "ecr" "elb" "kms")

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed."
        exit 1
    fi
}

# Function to check if AWS CLI is configured
check_aws_configured() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS CLI is not configured. Please run 'aws configure'."
        exit 1
    fi
}

# Function to validate service
validate_service() {
    for svc in "${SERVICES[@]}"; do
        if [[ "$1" == "$svc" ]]; then
            return 0
        fi
    done
    echo "Error: Unsupported service '$1'. Supported services are: ${SERVICES[*]}"
    exit 1
}

# Function to list resources
list_resources() {
    region="$1"
    service="$2"
    case "$service" in
        ec2)
            aws ec2 describe-instances --region "$region" --query "Reservations[].Instances[]" --output table
            ;;
        s3)
            aws s3api list-buckets --query "Buckets[].Name" --output table
            ;;
        lambda)
            aws lambda list-functions --region "$region" --output table
            ;;
        rds)
            aws rds describe-db-instances --region "$region" --output table
            ;;
        dynamodb)
            aws dynamodb list-tables --region "$region" --output table
            ;;
        cloudformation)
            aws cloudformation describe-stacks --region "$region" --output table
            ;;
        cloudwatch)
            aws cloudwatch describe-alarms --region "$region" --output table
            ;;
        sns)
            aws sns list-topics --region "$region" --output table
            ;;
        sqs)
            aws sqs list-queues --region "$region" --output table
            ;;
        iam)
            aws iam list-users --output table
            ;;
        elasticache)
            aws elasticache describe-cache-clusters --region "$region" --output table
            ;;
        eks)
            aws eks list-clusters --region "$region" --output table
            ;;
        ecr)
            aws ecr describe-repositories --region "$region" --output table
            ;;
        elb)
            aws elb describe-load-balancers --region "$region" --output table
            ;;
        kms)
            aws kms list-keys --region "$region" --output table
            ;;
        *)
            echo "Error: Service not implemented."
            exit 1
            ;;
    esac
}

# Main script
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <aws-region> <aws-service>"
    echo "Supported services: ${SERVICES[*]}"
    exit 1
fi

REGION="$1"
SERVICE="$2"

check_aws_cli
check_aws_configured
validate_service "$SERVICE"

list_resources "$REGION" "$SERVICE"
