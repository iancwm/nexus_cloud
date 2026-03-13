#!/bin/bash
set -e

# --- Configuration & Defaults ---
MOUNT_POINT="/mnt/persistent_config"
CONFIG_PATH="$HOME/.config"
SECRET_ID="nexus-cloud/ai-api-keys"
NODE_VERSION="20.x"
DEFAULT_DISK="/dev/xvdh"
DISK_SIZE_PATTERN="20G"

echo "--- Starting Nexus-Cloud Zero-Touch Setup ---"

# --- 1. Cloud Detection ---
# Support IMDSv2 for AWS
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || echo "")

if [ -n "$TOKEN" ] && curl -s -f -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id > /dev/null; then
    CLOUD_ENV="aws"
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
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
DISK_DEVICE="$DEFAULT_DISK"
if [ ! -b "$DISK_DEVICE" ]; then
    DISK_DEVICE=$(lsblk -p | grep "$DISK_SIZE_PATTERN" | awk '{print $1}' | head -n 1)
fi

if [ -b "$DISK_DEVICE" ]; then
    sudo mkdir -p $MOUNT_POINT
    # Format if no filesystem exists
    if ! sudo blkid $DISK_DEVICE > /dev/null; then
        echo "Formatting $DISK_DEVICE..."
        sudo mkfs -t ext4 $DISK_DEVICE
    fi
    # Mount if not already mounted
    if ! mountpoint -q $MOUNT_POINT; then
        sudo mount $DISK_DEVICE $MOUNT_POINT
        echo "Mounted $DISK_DEVICE to $MOUNT_POINT"
    else
        echo "Disk already mounted on $MOUNT_POINT."
    fi
    sudo chown $USER:$USER $MOUNT_POINT
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

# System Dependencies
sudo apt update && sudo apt install -y unzip jq curl

# UV - Fast Python Package Manager
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Source for both root and possible user paths
    [ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
    [ -f "/root/.local/bin/env" ] && source "/root/.local/bin/env"
    # Fallback: add to PATH directly for this script
    export PATH="$PATH:$HOME/.local/bin:/root/.local/bin"
fi

# Verify uv
UV_BIN=$(command -v uv || echo "/root/.local/bin/uv")
echo "Using uv at: $UV_BIN"

# ... rest of the script using $UV_BIN ...

# AWS CLI (if not present)
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Use UV for Python tools
$UV_BIN tool install llm --force
# Note: OpenAI is built-in. Plugins for others:
~/.local/bin/llm install llm-anthropic
~/.local/bin/llm install llm-gemini

# Aider - AI Pair Programming
$UV_BIN tool install aider-chat --force

# Developer Tools
# Node.js & NPM
if ! command -v node &> /dev/null; then
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}" | sudo -E bash -
    sudo apt install -y nodejs
fi

# Go
if ! command -v go &> /dev/null; then
    sudo apt install -y golang-go
fi

# Docker
if ! command -v docker &> /dev/null; then
    sudo apt install -y docker.io
    sudo usermod -aG docker $USER
fi

# Gemini CLI (Example: npm install)
if command -v npm &> /dev/null; then
    sudo npm install -g @google/gemini-cli
    
    echo "Installing Claude Code..."
    sudo npm install -g @anthropic-ai/claude-code
    
    echo "Installing OpenCode AI Agent..."
    sudo npm install -g opencode-ai
fi

# Cloud SDKs
# gcloud
if ! command -v gcloud &> /dev/null; then
    echo "Installing gcloud SDK..."
    export CLOUDSDK_INSTALL_DIR="/usr/local"
    export CLOUDSDK_CORE_DISABLE_PROMPTS=1
    curl -sSL https://sdk.cloud.google.com | bash -s -- --install-dir=/usr/local --disable-prompts > /dev/null
    
    # Add to global path
    [ -f "/usr/local/google-cloud-sdk/path.bash.inc" ] && source "/usr/local/google-cloud-sdk/path.bash.inc"
fi

# az (Azure CLI)
if ! command -v az &> /dev/null; then
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash > /dev/null
fi

# --- 5. IAM-Driven Secret Retrieval & Config ---
echo "Retrieving Secrets from Cloud..."
if [ "$CLOUD_ENV" == "aws" ]; then
    # Support IMDSv2 for AWS
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || echo "")
    if [ -z "$REGION" ] && [ -n "$TOKEN" ]; then
        REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
    fi
    
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID --region $REGION --query SecretString --output text 2>/dev/null || echo "{}")
    
    # Export keys to .bashrc for persistence
    ANTHROPIC_KEY=$(echo $SECRET_JSON | jq -r '.ANTHROPIC_API_KEY' 2>/dev/null)
    OPENAI_KEY=$(echo $SECRET_JSON | jq -r '.OPENAI_API_KEY' 2>/dev/null)
    GIT_NAME=$(echo $SECRET_JSON | jq -r '.GIT_USER_NAME' 2>/dev/null)
    GIT_EMAIL=$(echo $SECRET_JSON | jq -r '.GIT_USER_EMAIL' 2>/dev/null)

    if [ "$ANTHROPIC_KEY" != "null" ] && [ -n "$ANTHROPIC_KEY" ]; then
        echo "export ANTHROPIC_API_KEY=$ANTHROPIC_KEY" >> $HOME/.bashrc
        echo "Anthropic API Key loaded from Secrets Manager."
    fi
    if [ "$OPENAI_KEY" != "null" ] && [ -n "$OPENAI_KEY" ]; then
        echo "export OPENAI_API_KEY=$OPENAI_KEY" >> $HOME/.bashrc
        echo "OpenAI API Key loaded from Secrets Manager."
    fi

    # Git Configuration
    if [ "$GIT_NAME" != "null" ] && [ -n "$GIT_NAME" ]; then
        git config --global user.name "$GIT_NAME"
        echo "Git user.name configured: $GIT_NAME"
    fi
    if [ "$GIT_EMAIL" != "null" ] && [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
        echo "Git user.email configured: $GIT_EMAIL"
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
