# Nexus-Cloud Workspace Automation

# --- Configuration & Defaults ---
REGION        := "ap-northeast-1"
AMI           := ""
INSTANCE_TYPE := "t3.large"
NAME          := "nexus-cloud"
TIMESTAMP     := `date +%Y%m%d-%H%M`
VERSION_NAME  := NAME + "-" + TIMESTAMP
USER_ID       := "local-user"

# Resource Tags for lookup
WS_NAME       := NAME + "-workspace-" + USER_ID
VOL_NAME      := NAME + "-persistent-config-" + USER_ID

# Smart SSH Key Detection
SSH_PUB := if path_exists(home_dir() / ".ssh/id_nexus-cloud-project.pub") == "true" { read(home_dir() / ".ssh/id_nexus-cloud-project.pub") } else { if path_exists(home_dir() / ".ssh/id_ed25519.pub") == "true" { read(home_dir() / ".ssh/id_ed25519.pub") } else { if path_exists(home_dir() / ".ssh/id_rsa.pub") == "true" { read(home_dir() / ".ssh/id_rsa.pub") } else { "" } } }

# SSH Private Key path for remote commands
SSH_KEY := home_dir() / ".ssh/id_nexus-cloud-project"

# Get instance IP from Terraform output
IP := `terraform output -raw instance_public_ip 2>/dev/null || echo "none"`

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

# Internal helper to check for existing instance
check-existing:
	@EXISTING_ID=$$(aws ec2 describe-instances --region {{REGION}} --filters "Name=tag:Name,Values=*nexus-workspace*" "Name=instance-state-name,Values=running,pending,stopped" --query "Reservations[].Instances[].InstanceId" --output text); \
	if [ -n "$$EXISTING_ID" ]; then \
		echo "Workspace instance already exists (ID: $$EXISTING_ID). Skipping build."; \
		exit 1; \
	fi

# Build the infrastructure with idempotency checks
build: init
	@echo "Running idempotency checks for {{WS_NAME}}..."
	@just check-existing > /dev/null 2>&1 || { \
		echo "Found existing instance. If you want to re-provision, use 'just destroy-dangerously' first."; \
		exit 0; \
	}
	@echo "No existing workspace found. Provisioning..."
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

# Build the hosted Coder server
build-server DOMAIN ZONE_ID: init
	terraform apply -auto-approve \
		-var="deploy_coder_server=true" \
		-var="coder_domain_name={{DOMAIN}}" \
		-var="coder_route53_zone_id={{ZONE_ID}}" \
		-var="aws_region={{REGION}}"
	@just verify-server {{DOMAIN}}

# Verify the health of the hosted Coder server
verify-server DOMAIN:
	bash scripts/verify_server.sh {{DOMAIN}}

# Pause the workspace (Stop the EC2 instance)
stop:
	aws ec2 stop-instances --region {{REGION}} --instance-ids $(terraform output -raw instance_id)

# Resume the workspace (Start the EC2 instance)
start:
	aws ec2 start-instances --region {{REGION}} --instance-ids $(terraform output -raw instance_id)

# View outputs
status:
	terraform output

# Setup the remote instance: transfers files and runs setup.sh
setup-remote:
	@if [ "{{IP}}" = "none" ]; then echo "Error: No instance IP found. Run 'just build' first."; exit 1; fi
	@if [ ! -f "{{SSH_KEY}}" ]; then echo "Error: SSH private key not found at {{SSH_KEY}}. Set SSH_KEY='...'"; exit 1; fi
	scp -i {{SSH_KEY}} setup.sh sync_identity.sh nexus-sync.service ubuntu@{{IP}}:~/
	@ssh -i {{SSH_KEY}} ubuntu@{{IP}} "chmod +x setup.sh && ./setup.sh" || { \
		RET=$$?; \
		if [ $${RET} -ne 130 ] && [ $${RET} -ne 255 ]; then \
			echo "Error: setup-remote failed with exit code $${RET}"; \
			exit $${RET}; \
		fi; \
	}

# Connect to the remote instance
ssh:
	@if [ "{{IP}}" = "none" ]; then echo "Error: No instance IP found. Run 'just build' first."; exit 1; fi
	@ssh -i {{SSH_KEY}} ubuntu@{{IP}} || { \
		RET=$$?; \
		if [ $${RET} -ne 130 ] && [ $${RET} -ne 255 ] && [ $${RET} -ne 0 ]; then \
			echo "Error: ssh failed with exit code $${RET}"; \
			exit $${RET}; \
		fi; \
	}

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

# Create a secure public tunnel to your local Coder server (runs in background)
tunnel:
	@echo "Starting Cloudflare Tunnel to localhost:3000..."
	@echo "Wait for the 'trycloudflared.com' URL to appear below."
	cloudflared tunnel --url http://localhost:3000

# Start Coder server with a public Access URL (requires running 'just tunnel' in another terminal)
coder-server-public URL:
	coder server --access-url {{URL}}

# Push the current configuration as a Coder template (versioned by timestamp)
coder-push:
	@echo "Pushing versioned template: {{VERSION_NAME}}..."
	coder templates create {{VERSION_NAME}} --yes
