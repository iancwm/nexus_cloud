#!/bin/bash
# Nexus-Cloud Identity Sync Utility
# Handles S3 backup/restore of the /mnt/persistent_config volume

MOUNT_POINT="/mnt/persistent_config"
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region || echo "us-east-1")
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "local")

# Dynamically find the S3 bucket with the nexus-cloud-identity prefix
BUCKET_NAME=$(aws s3 ls --region "$REGION" | grep "nexus-cloud-identity-" | awk '{print $3}' | head -n 1)
S3_PATH="s3://${BUCKET_NAME}/${INSTANCE_ID}"

usage() {
    echo "Usage: $0 {push|pull}"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

ACTION=$1

case $ACTION in
    push)
        echo "Pushing identity snapshot to $S3_PATH..."
        if [ -d "$MOUNT_POINT" ]; then
            aws s3 sync "$MOUNT_POINT" "$S3_PATH" --delete --region "$REGION"
            echo "Identity snapshot synced to S3."
        else
            echo "Error: Mount point $MOUNT_POINT not found."
            exit 1
        fi
        ;;
    pull)
        echo "Pulling identity snapshot from $S3_PATH..."
        # Check if bucket exists/has content before pulling
        if aws s3 ls "$S3_PATH" --region "$REGION" > /dev/null 2>&1; then
            aws s3 sync "$S3_PATH" "$MOUNT_POINT" --region "$REGION"
            echo "Identity snapshot restored from S3."
        else
            echo "No remote snapshot found for this instance. Starting fresh."
        fi
        ;;
    *)
        usage
        ;;
esac
