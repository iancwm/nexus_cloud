# Nexus-Cloud Workspace Automation

# --- Variables ---
REGION := "us-east-1"
AMI := ""
INSTANCE_TYPE := "t3.large"

# --- Recipes ---

# Initialize everything
init:
    terraform init
    uv sync

# Securely set API keys in AWS Secrets Manager using uv
secrets ANTHROPIC OPENAI GEMINI:
    uv run manage_secrets.py set-keys --anthropic {{ANTHROPIC}} --openai {{OPENAI}} --gemini {{GEMINI}} --region {{REGION}}

# Build the infrastructure
build:
    terraform apply -auto-approve -var="aws_region={{REGION}}" -var="ami_id={{AMI}}" -var="instance_type={{INSTANCE_TYPE}}"

# Plan the infrastructure
plan:
    terraform plan -var="aws_region={{REGION}}" -var="ami_id={{AMI}}" -var="instance_type={{INSTANCE_TYPE}}"

# Tear down everything
tear-down:
    terraform destroy -auto-approve

# Refresh the local state
refresh:
    terraform refresh

# View outputs
status:
    terraform output
