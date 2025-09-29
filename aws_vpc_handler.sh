#!/bin/bash

###############################################################################
# aws_vpc_handler.sh
#
# Usage:
#   ./aws_vpc_handler.sh [create|destroy] <VPC_NAME>
#
# Description:
#   This script creates or destroys a multi-AZ AWS VPC environment with:
#     - 2 public subnets (Frontend & Backend EC2 instances)
#     - 1 private subnet (Multi-AZ MySQL RDS)
#     - Application Load Balancer (ALB) for public subnets
#     - Auto Scaling Group (ASG) for frontend
#     - S3 bucket for centralized log storage from all servers
#   All resources are tagged for easy identification.
#
# Requirements:
#   - AWS CLI configured with necessary permissions
#   - Replace AMI IDs, KeyPair names, and other values as needed
#
# Modularized for readability and reusability.
###############################################################################

set -e

#---------------------------#
# Global Configurations     #
#---------------------------#
ACTION=$1
VPC_NAME=$2

AWS_PROFILE="default"
AWS_REGION="us-east-1"

VPC_CIDR="10.0.0.0/16"
PUB1_CIDR="10.0.1.0/24"
PUB2_CIDR="10.0.2.0/24"
PRIV_CIDR="10.0.3.0/24"

AZ1="${AWS_REGION}a"
AZ2="${AWS_REGION}b"

AMI_ID="ami-0c94855ba95c71c99" # Replace with valid AMI
KEY_NAME="MyKeyPair"           # Replace with your key pair

#---------------------------#
# Helper Functions          #
#---------------------------#

# Tag AWS resource
tag_resource() {
    local resource_id=$1
    local name=$2
    aws ec2 create-tags --resources "$resource_id" --tags Key=Name,Value="$name" --profile $AWS_PROFILE --region $AWS_REGION
}

# Create S3 bucket for logs
create_s3_bucket() {
    local bucket_name="${VPC_NAME}-logs-$(date +%s)"
    aws s3api create-bucket --bucket $bucket_name --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION
    echo $bucket_name
}

# Setup EC2 instance log forwarding to S3 (user-data script)
get_log_forwarding_userdata() {
    local bucket_name=$1
    cat <<EOF
#!/bin/bash
LOG_PATH="/var/log"
DATE=\$(date +%Y-%m-%d)
aws s3 sync \$LOG_PATH s3://$bucket_name/\$(hostname)/\$DATE/ --region $AWS_REGION
(crontab -l 2>/dev/null; echo "0 * * * * aws s3 sync \$LOG_PATH s3://$bucket_name/\$(hostname)/\$DATE/ --region $AWS_REGION") | crontab -
EOF
}

# Create VPC and resources
create_vpc() {
    echo "Creating VPC: $VPC_NAME"

    # Create VPC
    VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    tag_resource $VPC_ID "$VPC_NAME"
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}" --profile $AWS_PROFILE --region $AWS_REGION
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}" --profile $AWS_PROFILE --region $AWS_REGION

    # Create Subnets
    PUB1_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUB1_CIDR --availability-zone $AZ1 --query 'Subnet.SubnetId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    tag_resource $PUB1_SUBNET_ID "${VPC_NAME}-public-1"
    aws ec2 modify-subnet-attribute --subnet-id $PUB1_SUBNET_ID --map-public-ip-on-launch --profile $AWS_PROFILE --region $AWS_REGION

    PUB2_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUB2_CIDR --availability-zone $AZ2 --query 'Subnet.SubnetId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    tag_resource $PUB2_SUBNET_ID "${VPC_NAME}-public-2"
    aws ec2 modify-subnet-attribute --subnet-id $PUB2_SUBNET_ID --map-public-ip-on-launch --profile $AWS_PROFILE --region $AWS_REGION

    PRIV_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIV_CIDR --availability-zone $AZ1 --query 'Subnet.SubnetId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    tag_resource $PRIV_SUBNET_ID "${VPC_NAME}-private-1"

    # Create Internet Gateway and attach
    IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    tag_resource $IGW_ID "${VPC_NAME}-igw"
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --profile $AWS_PROFILE --region $AWS_REGION

    # Create Route Tables
    PUB_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    tag_resource $PUB_RT_ID "${VPC_NAME}-public-rt"
    aws ec2 create-route --route-table-id $PUB_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --profile $AWS_PROFILE --region $AWS_REGION
    aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB1_SUBNET_ID --profile $AWS_PROFILE --region $AWS_REGION
    aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB2_SUBNET_ID --profile $AWS_PROFILE --region $AWS_REGION

    PRIV_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    tag_resource $PRIV_RT_ID "${VPC_NAME}-private-rt"
    aws ec2 associate-route-table --route-table-id $PRIV_RT_ID --subnet-id $PRIV_SUBNET_ID --profile $AWS_PROFILE --region $AWS_REGION

    # Security Groups
    FRONT_SG_ID=$(aws ec2 create-security-group --group-name "${VPC_NAME}-frontend-sg" --description "Frontend SG" --vpc-id $VPC_ID --query 'GroupId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    aws ec2 authorize-security-group-ingress --group-id $FRONT_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --profile $AWS_PROFILE --region $AWS_REGION

    BACK_SG_ID=$(aws ec2 create-security-group --group-name "${VPC_NAME}-backend-sg" --description "Backend SG" --vpc-id $VPC_ID --query 'GroupId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    aws ec2 authorize-security-group-ingress --group-id $BACK_SG_ID --protocol tcp --port 8080 --cidr $PUB1_CIDR --profile $AWS_PROFILE --region $AWS_REGION

    DB_SG_ID=$(aws ec2 create-security-group --group-name "${VPC_NAME}-db-sg" --description "DB SG" --vpc-id $VPC_ID --query 'GroupId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --cidr $PUB2_CIDR --profile $AWS_PROFILE --region $AWS_REGION

    # Create S3 bucket for logs
    LOG_BUCKET=$(create_s3_bucket)

    # Launch EC2 Instances with log forwarding user-data
    FRONT_INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID --count 1 --instance-type t3.micro --key-name $KEY_NAME \
        --subnet-id $PUB1_SUBNET_ID --security-group-ids $FRONT_SG_ID --associate-public-ip-address \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${VPC_NAME}-frontend}]" \
        --user-data "$(get_log_forwarding_userdata $LOG_BUCKET)" \
        --profile $AWS_PROFILE --region $AWS_REGION --query 'Instances[0].InstanceId' --output text)

    BACK_INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID --count 1 --instance-type t3.micro --key-name $KEY_NAME \
        --subnet-id $PUB2_SUBNET_ID --security-group-ids $BACK_SG_ID --associate-public-ip-address \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${VPC_NAME}-backend}]" \
        --user-data "$(get_log_forwarding_userdata $LOG_BUCKET)" \
        --profile $AWS_PROFILE --region $AWS_REGION --query 'Instances[0].InstanceId' --output text)

    # Create RDS MySQL in private subnet (multi-AZ, automatic replication)
    DB_SUBNET_GROUP=$(aws rds create-db-subnet-group \
        --db-subnet-group-name "${VPC_NAME}-db-subnet-group" \
        --db-subnet-group-description "DB subnet group" \
        --subnet-ids $PRIV_SUBNET_ID \
        --profile $AWS_PROFILE --region $AWS_REGION --query 'DBSubnetGroup.DBSubnetGroupName' --output text)

    DB_INSTANCE_ID="${VPC_NAME}-mysql-db"
    aws rds create-db-instance \
        --db-instance-identifier $DB_INSTANCE_ID \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --master-username admin \
        --master-user-password 'StrongPassword123!' \
        --allocated-storage 20 \
        --vpc-security-group-ids $DB_SG_ID \
        --db-subnet-group-name $DB_SUBNET_GROUP \
        --multi-az \
        --no-publicly-accessible \
        --profile $AWS_PROFILE --region $AWS_REGION

    # Note: Multi-AZ RDS ensures synchronous replication between AZs for high availability.

    # Create Load Balancer (ALB) for public subnets
    LB_ARN=$(aws elbv2 create-load-balancer \
        --name "${VPC_NAME}-alb" \
        --subnets $PUB1_SUBNET_ID $PUB2_SUBNET_ID \
        --security-groups $FRONT_SG_ID $BACK_SG_ID \
        --type application --scheme internet-facing \
        --profile $AWS_PROFILE --region $AWS_REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text)

    # Create Target Groups and Register Targets
    TG_FRONT_ARN=$(aws elbv2 create-target-group \
        --name "${VPC_NAME}-tg-front" --protocol HTTP --port 80 --vpc-id $VPC_ID --target-type instance \
        --profile $AWS_PROFILE --region $AWS_REGION --query 'TargetGroupArn' --output text)
    TG_BACK_ARN=$(aws elbv2 create-target-group \
        --name "${VPC_NAME}-tg-back" --protocol HTTP --port 8080 --vpc-id $VPC_ID --target-type instance \
        --profile $AWS_PROFILE --region $AWS_REGION --query 'TargetGroupArn' --output text)
    aws elbv2 register-targets --target-group-arn $TG_FRONT_ARN --targets Id=$FRONT_INSTANCE_ID --profile $AWS_PROFILE --region $AWS_REGION
    aws elbv2 register-targets --target-group-arn $TG_BACK_ARN --targets Id=$BACK_INSTANCE_ID --profile $AWS_PROFILE --region $AWS_REGION

    # Create Listeners
    aws elbv2 create-listener --load-balancer-arn $LB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_FRONT_ARN --profile $AWS_PROFILE --region $AWS_REGION
    aws elbv2 create-listener --load-balancer-arn $LB_ARN --protocol HTTP --port 8080 --default-actions Type=forward,TargetGroupArn=$TG_BACK_ARN --profile $AWS_PROFILE --region $AWS_REGION

    # Create Launch Template for ASG
    LAUNCH_TEMPLATE_ID=$(aws ec2 create-launch-template \
        --launch-template-name "${VPC_NAME}-lt" \
        --version-description "v1" \
        --launch-template-data "ImageId=$AMI_ID,InstanceType=t3.micro,KeyName=$KEY_NAME,SecurityGroupIds=[$FRONT_SG_ID],SubnetId=$PUB1_SUBNET_ID,UserData=$(echo -n "$(get_log_forwarding_userdata $LOG_BUCKET)" | base64)" \
        --profile $AWS_PROFILE --region $AWS_REGION --query 'LaunchTemplate.LaunchTemplateId' --output text)

    # Create Auto Scaling Group for Frontend
    ASG_FRONT_NAME="${VPC_NAME}-asg-front"
    aws autoscaling create-auto-scaling-group \
        --auto-scaling-group-name $ASG_FRONT_NAME \
        --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID,Version=1 \
        --min-size 1 --max-size 5 --desired-capacity 2 \
        --vpc-zone-identifier "$PUB1_SUBNET_ID,$PUB2_SUBNET_ID" \
        --profile $AWS_PROFILE --region $AWS_REGION

    # Scaling policies (scale up during business hours, scale down otherwise)
    aws autoscaling put-scheduled-update-group-action \
        --auto-scaling-group-name $ASG_FRONT_NAME \
        --scheduled-action-name "ScaleUpBusinessHours" \
        --recurrence "0 9 * * 1-5" \
        --min-size 2 --max-size 5 --desired-capacity 4 \
        --profile $AWS_PROFILE --region $AWS_REGION
    aws autoscaling put-scheduled-update-group-action \
        --auto-scaling-group-name $ASG_FRONT_NAME \
        --scheduled-action-name "ScaleDownOffHours" \
        --recurrence "0 18 * * 1-5" \
        --min-size 1 --max-size 2 --desired-capacity 1 \
        --profile $AWS_PROFILE --region $AWS_REGION

    echo "VPC $VPC_NAME and resources created successfully."
}

# Destroy VPC and resources (simplified)
destroy_vpc() {
    echo "Destroying VPC: $VPC_NAME"
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text --profile $AWS_PROFILE --region $AWS_REGION)
    if [[ "$VPC_ID" == "None" ]]; then
        echo "VPC $VPC_NAME not found."
        exit 1
    fi
    # NOTE: In production, delete all dependent resources before deleting VPC.
    aws ec2 delete-vpc --vpc-id $VPC_ID --profile $AWS_PROFILE --region $AWS_REGION
    echo "VPC $VPC_NAME deleted. Please manually clean up dependent resources if needed."
}

#---------------------------#
# Main Logic                #
#---------------------------#

if [[ -z "$ACTION" || -z "$VPC_NAME" ]]; then
    echo "Usage: $0 [create|destroy] <VPC_NAME>"
    exit 1
fi

case "$ACTION" in
    create)
        create_vpc
        ;;
    destroy)
        destroy_vpc
        ;;
    *)
        echo "Invalid action: $ACTION"
        exit 1
        ;;
esac