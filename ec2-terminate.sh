#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0b942f163a765c6b4"
ZONE_ID="Z031668720LL13SP2V0EM"
DOMAIN_NAME="bingi.online"

for instance in "$@"
do
    echo "Processing $instance ..."

    # Get instance ID by Name tag
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance" "Name=instance-state-name,Values=running,stopped" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text)

    if [ -z "$INSTANCE_ID" ]; then
        echo "No instance found for $instance"
        continue
    fi

    # Decide record name
    if [ "$instance" == "frontend" ]; then
        RECORD_NAME="roboshop.$DOMAIN_NAME"
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text)
    else
        RECORD_NAME="$instance.$DOMAIN_NAME"
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text)
    fi

    echo "Deleting Route53 record: $RECORD_NAME -> $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch "
    {
        \"Comment\": \"Deleting record\",
        \"Changes\": [{
            \"Action\": \"DELETE\",
            \"ResourceRecordSet\": {
                \"Name\": \"$RECORD_NAME\",
                \"Type\": \"A\",
                \"TTL\": 1,
                \"ResourceRecords\": [{\"Value\": \"$IP\"}]
            }
        }]
    }
    "

    echo "Terminating EC2 instance: $INSTANCE_ID"

    aws ec2 terminate-instances \
        --instance-ids $INSTANCE_ID \
        --output table

    echo "Cleanup done for $instance"
    echo "--------------------------------"
done
