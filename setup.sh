#!/bin/bash
set -e

# --- Configuration & Defaults ---
MOUNT_POINT="/mnt/persistent_config"
CONFIG_PATH="$HOME/.config"
SECRET_ID="nexus-cloud/ai-api-keys"

echo "--- Starting Nexus-Cloud Zero-Touch Setup ---"

# --- 1. Cloud Detection ---
if curl -s -f http://169.254.169.254/latest/meta-data/instance-id > /dev/null; then
    CLOUD_ENV="aws"
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    echo "Detected Cloud: AWS ($REGION)"
elif curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id > /dev/null; then
    CLOUD_ENV="gcp"
    echo "Detected Cloud: GCP"
else
    echo "Unknown Cloud Environment. Proceeding with generic setup."
    CLOUD_ENV="unknown"
fi

# --- 2. Persistent Disk Mounting ---
echo "Configuring Persistent Storage..."
# AWS specific: /dev/sdh is often /dev/xvdh or /dev/nvme1n1
DISK_DEVICE="/dev/xvdh"
if [ ! -b "$DISK_DEVICE" ]; then
    DISK_DEVICE=$(lsblk -p | grep "20G" | awk '{print $1}' | head -n 1)
fi

if [ -b "$DISK_DEVICE" ]; then
    sudo mkdir -p $MOUNT_POINT
    # Format if no filesystem exists
    if ! sudo blkid $DISK_DEVICE > /dev/null; then
        echo "Formatting $DISK_DEVICE..."
        sudo mkfs -t ext4 $DISK_DEVICE
    fi
    sudo mount $DISK_DEVICE $MOUNT_POINT
    sudo chown $USER:$USER $MOUNT_POINT
    echo "Mounted $DISK_DEVICE to $MOUNT_POINT"
else
    echo "Warning: Persistent disk not found. Storage will be ephemeral."
fi

# --- 3. Symlinking Identity ---
echo "Symlinking .config to persistent storage..."
mkdir -p $MOUNT_POINT/.config
if [ -d "$CONFIG_PATH" ] && [ ! -L "$CONFIG_PATH" ]; then
    mv $CONFIG_PATH/* $MOUNT_POINT/.config/ 2>/dev/null || true
    rm -rf $CONFIG_PATH
fi
ln -sfn $MOUNT_POINT/.config $CONFIG_PATH

# --- 4. Toolchain Installation ---
echo "Installing AI Toolchain..."

# UV - Fast Python Package Manager
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env
fi

# AWS CLI (if not present)
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Use UV for Python tools
uv tool install llm --force
uv tool install openai --force
uv tool install anthropic --force

# Gemini CLI (Example: npm install)
if command -v npm &> /dev/null; then
    sudo npm install -g @google/gemini-cli
fi


# Claude Code (Anthropic)
# (Assuming a direct install or npm package)
# sudo npm install -g @anthropic-ai/claude-code

# --- 5. IAM-Driven Secret Retrieval ---
echo "Retrieving Secrets from Cloud..."
if [ "$CLOUD_ENV" == "aws" ]; then
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID --region $REGION --query SecretString --output text 2>/dev/null || echo "{}")
    
    # Export keys to .bashrc for persistence
    ANTHROPIC_KEY=$(echo $SECRET_JSON | jq -r '.ANTHROPIC_API_KEY' 2>/dev/null)
    OPENAI_KEY=$(echo $SECRET_JSON | jq -r '.OPENAI_API_KEY' 2>/dev/null)

    if [ "$ANTHROPIC_KEY" != "null" ] && [ -n "$ANTHROPIC_KEY" ]; then
        echo "export ANTHROPIC_API_KEY=$ANTHROPIC_KEY" >> $HOME/.bashrc
        echo "Anthropic API Key loaded from Secrets Manager."
    fi
    if [ "$OPENAI_KEY" != "null" ] && [ -n "$OPENAI_KEY" ]; then
        echo "export OPENAI_API_KEY=$OPENAI_KEY" >> $HOME/.bashrc
        echo "OpenAI API Key loaded from Secrets Manager."
    fi
fi

# --- 6. Disaster Recovery: Identity Sync ---
echo "Configuring Identity Sync (Disaster Recovery)..."
sudo cp sync_identity.sh /usr/local/bin/sync_identity.sh
sudo chmod +x /usr/local/bin/sync_identity.sh

if [ -f "nexus-sync.service" ]; then
    sudo cp nexus-sync.service /etc/systemd/system/nexus-sync.service
    sudo systemctl daemon-reload
    sudo systemctl enable nexus-sync.service
    echo "Disaster recovery service enabled (nexus-sync.service)."
fi

echo "--- Nexus-Cloud Setup Complete ---"
echo "Restart your shell or run 'source ~/.bashrc' to apply changes."
