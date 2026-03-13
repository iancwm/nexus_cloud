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

# Initialize everything and ensure dependencies like Coder and SSM plugin are present
init:
	terraform init
	uv sync
	@if ! command -v coder &> /dev/null; then \
		echo "Installing Coder CLI..."; \
		curl -L https://coder.com/install.sh | sh; \
	fi
	@if ! command -v session-manager-plugin &> /dev/null; then \
		echo "Installing AWS Session Manager Plugin..."; \
		curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb"; \
		sudo dpkg -i /tmp/session-manager-plugin.deb; \
		rm /tmp/session-manager-plugin.deb; \
	fi

# Securely set API keys in AWS Secrets Manager using uv
secrets ANTHROPIC OPENAI GEMINI:
	uv run manage_secrets.py set-keys --anthropic {{ANTHROPIC}} --openai {{OPENAI}} --gemini {{GEMINI}} --region {{REGION}}

# Build the infrastructure with idempotency checks (Standalone Path)
build: init
	@echo "Running idempotency checks for {{WS_NAME}}..."
	@aws ec2 describe-instances --region {{REGION}} --filters "Name=tag:Name,Values=*nexus-workspace*" "Name=instance-state-name,Values=running,pending,stopped" --query "Reservations[].Instances[].InstanceId" --output text | grep -q "." && { \
		echo "Workspace instance already exists. Skipping build."; \
		echo "If you want to re-provision, use 'just destroy-dangerously' first."; \
		exit 0; \
	} || true
	@echo "No existing workspace found. Provisioning..."
	terraform apply -auto-approve \
		-var="aws_region={{REGION}}" \
		-var="instance_type={{INSTANCE_TYPE}}" \
		-var="ami_id={{AMI}}" \
		-var="ssh_public_key={{SSH_PUB}}"

# Plan the infrastructure changes
plan:
	terraform plan \
		-var="aws_region={{REGION}}" \
		-var="instance_type={{INSTANCE_TYPE}}" \
		-var="ami_id={{AMI}}" \
		-var="ssh_public_key={{SSH_PUB}}"

# Build the hosted Coder control plane (Cloud-Native Path)
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

# Configure local SSH to use SSM Proxy for zero-port connectivity (One-time setup)
ssm-setup:
	@terraform output -raw instance_id | xargs -I {} just _ssm-config-apply {}

# Internal helper to write the SSH config (do not use directly)
_ssm-config-apply ID:
	@if grep -q "Host nexus-workspace" ~/.ssh/config; then \
		sed -i "/Host nexus-workspace/,/ProxyCommand/d" ~/.ssh/config; \
	fi; \
	echo "Configuring SSM Proxy for {{ID}}..."; \
	printf "\nHost nexus-workspace\n  HostName {{ID}}\n  User ubuntu\n  IdentityFile {{SSH_KEY}}\n  ProxyCommand sh -c \"aws ssm start-session --target %%h --document-name AWS-StartSSHSession --parameters 'portNumber=%%p' --region {{REGION}}\"\n" >> ~/.ssh/config; \
	echo "✅ Done. You can now use 'ssh nexus-workspace'."

# Setup the remote instance via secure SSM tunnel: transfers files and runs setup.sh
setup-remote:
	@if [ "{{IP}}" = "none" ]; then echo "Error: No instance IP found. Run 'just build' first."; exit 1; fi
	scp setup.sh sync_identity.sh nexus-sync.service nexus-workspace:~/
	@ssh nexus-workspace "chmod +x setup.sh && ./setup.sh" || { \
		RET=$$?; \
		if [ $${RET} -ne 130 ] && [ $${RET} -ne 255 ]; then \
			echo "Error: setup-remote failed with exit code $${RET}"; \
			exit $${RET}; \
		fi; \
	}

# Connect to the remote instance securely via SSM tunnel
ssh:
	@ssh nexus-workspace || { \
		RET=$$?; \
		if [ $${RET} -ne 130 ] && [ $${RET} -ne 255 ] && [ $${RET} -ne 0 ]; then \
			echo "Error: ssh failed with exit code $${RET}"; \
			exit $${RET}; \
		fi; \
	}

# Pause the workspace (Stop the EC2 instance, keep EBS data)
stop:
	aws ec2 stop-instances --region {{REGION}} --instance-ids $(terraform output -raw instance_id)

# Resume the workspace (Start the EC2 instance)
start:
	aws ec2 start-instances --region {{REGION}} --instance-ids $(terraform output -raw instance_id)

# View current infrastructure outputs
status:
	terraform output

# Tear down ephemeral resources (fails if persistent EBS exists)
tear-down:
	terraform destroy -auto-approve

# DANGER: Fully wipe the workspace, including persistent identity disks
destroy-dangerously:
	@echo "WARNING: This will permanently delete your persistent config disk."
	@echo "Proceeding in 5 seconds... (Ctrl+C to abort)"
	@sleep 5
	sed -i 's/prevent_destroy = true/prevent_destroy = false/g' modules/aws/main.tf
	terraform destroy -auto-approve
	sed -i 's/prevent_destroy = false/prevent_destroy = true/g' modules/aws/main.tf

# Refresh the local Terraform state
refresh:
	terraform refresh

# Interactive setup wizard to configure Identity (AWS and AI keys)
wizard:
	uv run nexus_wizard.py wizard

# Run diagnostics to detect common setup and connectivity errors
debug:
	uv run nexus_wizard.py debug

# Create a secure public tunnel to your local Coder server
tunnel:
	@echo "Starting Cloudflare Tunnel to localhost:3000..."
	@echo "Wait for the 'trycloudflared.com' URL to appear below."
	cloudflared tunnel --url http://localhost:3000

# Start Coder server with a public Access URL (requires 'just tunnel')
coder-server-public URL:
	coder server --access-url {{URL}}

# Push current config as a versioned Coder template (Dashboard path)
coder-push:
	@echo "Pushing versioned template: {{VERSION_NAME}}..."
	coder templates create {{VERSION_NAME}} --yes
