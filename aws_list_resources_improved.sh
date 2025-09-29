#!/bin/bash
###############################################################################
# aws_list_resources.sh
# Lists AWS resources for a specified region and service.
# Author: Veeramalla Abhi
###############################################################################

# Supported AWS services
readonly SERVICES=("ec2" "s3" "lambda" "rds" "dynamodb" "cloudformation" "cloudwatch" "sns" "sqs" "iam" "elasticache" "eks" "ecr" "elb" "kms")

# Print usage
usage() {
    echo "Usage: $0 <aws-region> <aws-service>"
    echo "Supported services: ${SERVICES[*]}"
    exit 1
}

# Check if AWS CLI is installed
require_aws_cli() {
    command -v aws &> /dev/null || { echo "Error: AWS CLI is not installed."; exit 1; }
}

# Check if AWS CLI is configured
require_aws_configured() {
    aws sts get-caller-identity &> /dev/null || { echo "Error: AWS CLI is not configured. Please run 'aws configure'."; exit 1; }
}

# Validate service
validate_service() {
    local svc="$1"
    for s in "${SERVICES[@]}"; do
        [[ "$svc" == "$s" ]] && return 0
    done
    echo "Error: Unsupported service '$svc'. Supported services: ${SERVICES[*]}"
    exit 1
}

# Resource listing functions
list_ec2()          { aws ec2 describe-instances --region "$1" --query "Reservations[].Instances[]" --output table; }
list_s3()           { aws s3api list-buckets --query "Buckets[].Name" --output table; }
list_lambda()       { aws lambda list-functions --region "$1" --output table; }
list_rds()          { aws rds describe-db-instances --region "$1" --output table; }
list_dynamodb()     { aws dynamodb list-tables --region "$1" --output table; }
list_cloudformation(){ aws cloudformation describe-stacks --region "$1" --output table; }
list_cloudwatch()   { aws cloudwatch describe-alarms --region "$1" --output table; }
list_sns()          { aws sns list-topics --region "$1" --output table; }
list_sqs()          { aws sqs list-queues --region "$1" --output table; }
list_iam()          { aws iam list-users --output table; }
list_elasticache()  { aws elasticache describe-cache-clusters --region "$1" --output table; }
list_eks()          { aws eks list-clusters --region "$1" --output table; }
list_ecr()          { aws ecr describe-repositories --region "$1" --output table; }
list_elb()          { aws elb describe-load-balancers --region "$1" --output table; }
list_kms()          { aws kms list-keys --region "$1" --output table; }

# Dispatch resource listing
list_resources() {
    local region="$1" service="$2"
    case "$service" in
        ec2)           list_ec2 "$region" ;;
        s3)            list_s3 ;;
        lambda)        list_lambda "$region" ;;
        rds)           list_rds "$region" ;;
        dynamodb)      list_dynamodb "$region" ;;
        cloudformation)list_cloudformation "$region" ;;
        cloudwatch)    list_cloudwatch "$region" ;;
        sns)           list_sns "$region" ;;
        sqs)           list_sqs "$region" ;;
        iam)           list_iam ;;
        elasticache)   list_elasticache "$region" ;;
        eks)           list_eks "$region" ;;
        ecr)           list_ecr "$region" ;;
        elb)           list_elb "$region" ;;
        kms)           list_kms "$region" ;;
        *)             echo "Error: Service not implemented."; exit 1 ;;
    esac
}

main() {
    [[ $# -ne 2 ]] && usage
    local region="$1" service="$2"
    require_aws_cli
    require_aws_configured
    validate_service "$service"
    list_resources "$region" "$service"
}

main "$@"