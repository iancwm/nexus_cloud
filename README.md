# ☁️ Nexus-Cloud AI Workspace

A **zero-footprint** Infrastructure-as-Code (IaC) repository that provisions a persistent, high-performance coding environment optimized for terminal-based AI agents.

---

## 🏗 Key Features

- **Zero-Touch Identity**: No local credentials stored. API keys are fetched from **AWS Secrets Manager** via **IAM Instance Profiles**.
- **Dual-Layer Persistence**: Standard config paths (`~/.config`) are symlinked to a persistent 20GB EBS volume that survives instance destruction.
- **Cross-Instance Recovery**: Automatic **S3 Identity Snapshots** on shutdown; seamless restoration on boot via `systemd`.
- **Full Productivity Suite**: Pre-configured with `uv`, `llm`, `aider`, `claude-code`, `opencode-ai`, `docker`, `node`, `go`, and all major cloud SDKs (`aws`, `gcloud`, `az`).
- **Observability**: Real-time installation logs streamed directly to your Coder dashboard.
- **Networking Bridge**: Automated Cloudflare Tunnels to link local Coder servers to AWS agents.

---

## 🛡 Security & Permissions

### ⚠️ IMPORTANT: Cloud CLI Configuration
*   **ADMIN RIGHTS REQUIRED:** Ensure your Cloud Provider's CLI (e.g., `aws`) is configured with an **ADMIN ACCOUNT**. Provisioning Infrastructure (IAM Roles, VPCs, Secrets) requires full administrative privileges. 
*   **NO MANUAL MODIFICATIONS:** Never modify Terraform state or configuration files manually. Use the provided tools to manage your workspace.

---

## ⚡️ Detailed Walkthrough

### 1. Initialize Your Identity
Run the interactive setup wizard to configure your region, AI API keys, and Git identity. This information is used to generate a local `config.yaml` and securely populate AWS Secrets Manager.
```bash
just wizard
```

### 2. Choose Your Deployment Path

#### Option A: Standalone Deployment (CLI Only)
Use this if you want to control AWS directly from your terminal without a dashboard.

1. **Build**: `just build` (Provisions VPC, EC2, and IAM).
2. **Setup**: `just setup-remote` (Transfers scripts and installs toolchain).
3. **Connect**: `just ssh` (Installs tools and starts prompting).

#### Option B: Coder Dashboard (Recommended)
Use this for a seamless, multi-workspace dashboard experience.

1. **Start the Network Bridge**:
   In a dedicated terminal, run `just tunnel`. Copy the `trycloudflared.com` URL.
2. **Launch Coder**:
   In another terminal, run `just coder-server-public <YOUR_TUNNEL_URL>`.
3. **Push the Template**:
   Run `just coder-push`. This uploads your configuration as a versioned template.
4. **Create Workspace**: 
   Open the Coder UI in your browser, select the latest template, and click **Create Workspace**. 
   *Select your region and disk size directly in the dashboard.*

---

## 🔧 Automation Commands (`justfile`)

| Command | Description |
| :--- | :--- |
| `just wizard` | Guided interactive setup for all keys and identity. |
| `just debug` | Diagnostic suite to verify environment and AWS connectivity. |
| `just tunnel` | Creates a secure bridge for localhost-to-cloud networking. |
| `just build` | Standard Terraform deployment (Standalone path). |
| `just coder-push` | Pushes a timestamp-versioned template to Coder. |
| `just stop` / `just start` | Pause/Resume the workspace to save costs. |
| `just destroy-dangerously` | Wipes the entire environment, including persistent disks. |

---

## 📁 Repository Structure

- `modules/aws/`: Core infrastructure definitions (VPC, IAM, EC2, S3).
- `setup.sh`: The "Universal Provisioner" that installs the toolchain.
- `sync_identity.sh`: Handles EBS-to-S3 identity backups.
- `nexus_wizard.py`: Interactive configuration and secret handler.
- `specs/`: Technical specifications for the entire system.
