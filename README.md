# ☁️ Nexus-Cloud AI Workspace

A **zero-footprint** Infrastructure-as-Code (IaC) repository that provisions a persistent, high-performance coding environment optimized for terminal-based AI agents.

---

## 🏗 Key Features

- **Zero-Port Security**: No open inbound ports (Port 22 closed). Connectivity is handled via **AWS SSM Session Manager**.
- **VS Code Native**: Seamless integration via `ssh nexus-workspace` using an automated SSM Proxy configuration.
- **Zero-Touch Identity**: No local credentials stored. API keys are fetched from **AWS Secrets Manager** via **IAM Instance Profiles**.
- **Dual-Layer Persistence**: Standard config paths (`~/.config`) are symlinked to a persistent 20GB EBS volume that survives instance destruction.
- **Cross-Instance Recovery**: Automatic **S3 Identity Snapshots** on shutdown; seamless restoration on boot via `systemd`.
- **Full Productivity Suite**: Pre-configured with `uv`, `llm`, `aider`, `claude-code`, `opencode-ai`, `docker`, `node`, `go`, and all major cloud SDKs.

---

## 🛡 Security & Permissions

### ⚠️ IMPORTANT: Cloud CLI Configuration
*   **ADMIN RIGHTS REQUIRED:** Ensure your Cloud Provider's CLI (e.g., `aws`) is configured with an **ADMIN ACCOUNT**. Provisioning Infrastructure (IAM Roles, VPCs, Secrets) requires full administrative privileges. 
*   **NO MANUAL MODIFICATIONS:** Never modify Terraform state or configuration files manually. Use the provided tools to manage your workspace.

---

## ⚡️ Deployment Walkthrough

### 1. Initialize Your Identity
Run the setup wizard to configure your region, AI API keys, and Git identity.
```bash
just wizard
```

### 2. Provision Your Workspace
Run `just build` to provision your AWS infrastructure. Once complete, run the one-time SSM setup to configure your local SSH:
```bash
just build
just ssm-setup
```

### 3. Setup & Connect
1. **Initialize Tools**: `just setup-remote` (Automatically tunnels via SSM).
2. **Connect**: `just ssh` (or use VS Code Remote-SSH to `nexus-workspace`).

---

## 🔧 Automation Commands (`justfile`)

| Command | Description |
| :--- | :--- |
| `just wizard` | Guided interactive setup for all keys and identity. |
| `just ssm-setup` | One-time local SSH configuration for secure SSM Proxy access. |
| `just build` | Standalone Terraform deployment (CLI Only). |
| `just setup-remote` | Remote execution of the provisioner via SSM tunnel. |
| `just ssh` | Instant secure connection to your workspace. |
| `just coder-push` | Pushes a timestamp-versioned template to Coder. |
| `just tunnel` | Creates a secure bridge for localhost-to-cloud networking. |
| `just stop` / `just start` | Pause/Resume the workspace instance. |
| `just destroy-dangerously` | Wipes the entire environment, including persistent disks. |

---

## 📁 Repository Structure

- `modules/aws/`: Workspace infrastructure definitions (VPC, IAM, EC2, S3).
- `setup.sh`: The "Universal Provisioner" that installs the toolchain.
- `nexus_wizard.py`: Interactive configuration and secret handler.
- `sync_identity.sh`: Handles EBS-to-S3 identity backups.
- `specs/`: Technical specifications for the entire system.
