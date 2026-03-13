# Nexus-Cloud Workspace Automation

# --- Variables (Overridable via CLI) ---
REGION := "ap-northeast-1"
AMI := ""
INSTANCE_TYPE := "t3.large"

# Smart SSH Key Detection: Use provided key, or look for id_ed25519, or id_rsa
SSH_PUB := if path_exists(home_dir() / ".ssh/id_ed25519.pub") == "true" { read(home_dir() / ".ssh/id_ed25519.pub") } else { if path_exists(home_dir() / ".ssh/id_rsa.pub") == "true" { read(home_dir() / ".ssh/id_rsa.pub") } else { "" } }

# --- Recipes ---

# Initialize everything and ensure dependencies like Coder are present
init:
    terraform init
    uv sync
    @if ! command -v coder &> /dev/null; then \
        echo "Installing Coder CLI..."; \
        curl -L https://coder.com/install.sh | sh; \
    fi

# Securely set API keys in AWS Secrets Manager using uv
secrets ANTHROPIC OPENAI GEMINI:
    uv run manage_secrets.py set-keys --anthropic {{ANTHROPIC}} --openai {{OPENAI}} --gemini {{GEMINI}} --region {{REGION}}

# Build the infrastructure
build: init
    @if [ -z "{{SSH_PUB}}" ]; then echo "Error: No SSH public key found in ~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub. Please provide SSH_PUB='...'"; exit 1; fi
    terraform apply -auto-approve \
      -var="aws_region={{REGION}}" \
      -var="instance_type={{INSTANCE_TYPE}}" \
      -var="ami_id={{AMI}}" \
      -var="ssh_public_key={{SSH_PUB}}"

# Plan the infrastructure
plan:
    terraform plan \
      -var="aws_region={{REGION}}" \
      -var="instance_type={{INSTANCE_TYPE}}" \
      -var="ami_id={{AMI}}" \
      -var="ssh_public_key={{SSH_PUB}}"

# Pause the workspace (Stop the EC2 instance)
stop:
    aws ec2 stop-instances --region {{REGION}} --instance-ids $(terraform output -raw instance_id)

# Resume the workspace (Start the EC2 instance)
start:
    aws ec2 start-instances --region {{REGION}} --instance-ids $(terraform output -raw instance_id)

# View outputs
status:
    terraform output

# Tear down everything (Safety-first: will fail if persistent disk exists)
tear-down:
    terraform destroy -auto-approve

# DANGER: Fully wipe the workspace, including persistent disks
destroy-dangerously:
    @echo "WARNING: This will permanently delete your persistent config disk."
    @echo "Proceeding in 5 seconds... (Ctrl+C to abort)"
    @sleep 5
    sed -i 's/prevent_destroy = true/prevent_destroy = false/g' modules/aws/main.tf
    terraform destroy -auto-approve
    sed -i 's/prevent_destroy = false/prevent_destroy = true/g' modules/aws/main.tf

# Refresh the local state
refresh:
    terraform refresh

# Interactive setup wizard to configure AWS and AI keys
wizard:
    uv run nexus_wizard.py wizard

# Run diagnostics to detect common setup and connectivity errors
debug:
    uv run nexus_wizard.py debug
