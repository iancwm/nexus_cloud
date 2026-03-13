# ☁️ Nexus-Cloud AI Workspace

A **zero-footprint** Infrastructure-as-Code (IaC) repository that provisions a persistent, high-performance coding environment optimized for terminal-based AI agents.

---

## 🏗 Key Features

- **Zero-Touch Identity**: No local credentials stored. API keys are fetched from **AWS Secrets Manager** via **IAM Instance Profiles**.
- **Dual-Layer Persistence**: Standard config paths (`~/.config`) are symlinked to a persistent 20GB EBS volume that survives instance destruction.
- **Cross-Instance Recovery**: Automatic **S3 Identity Snapshots** on shutdown; seamless restoration on boot via `systemd`.
- **Full Productivity Suite**: Pre-configured with `uv`, `llm`, `aider`, `claude-code`, `opencode-ai`, `docker`, `node`, `go`, and all major cloud SDKs.
- **Hosted Coder Option**: Deploy a permanent, centralized Coder control plane on AWS with your own domain and SSL.
- **Networking Bridge**: Automated Cloudflare Tunnels for local Coder deployments.

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

### 2. Choose Your Coder Deployment

#### Option A: Hosted Coder Server (Cloud-Native)
Use this for a permanent, secure Coder dashboard accessible from anywhere.
1. **Build**: `just build-server <domain> <route53_zone_id>`
   *   *This provisions an ALB, EC2, ACM Certificate, and DNS records.*
2. **Access**: Open `https://<domain>` and create your admin account.

#### Option B: Local Coder Dashboard (Development)
Use this for a quick, local-only dashboard experience.
1. **Start Tunnel**: Run `just tunnel` and copy the URL.
2. **Launch Coder**: Run `just coder-server-public <TUNNEL_URL>`.

### 3. Provision Your Workspace
1. **Push Template**: Run `just coder-push`.
2. **Dashboard**: Open your Coder URL, select the template, and click **Create Workspace**.

---

## 🔧 Automation Commands (`justfile`)

| Command | Description |
| :--- | :--- |
| `just wizard` | Guided interactive setup for all keys and identity. |
| `just build-server` | Deploy a permanent Coder server on AWS with SSL/DNS. |
| `just verify-server` | Automated health check for the hosted Coder server. |
| `just coder-push` | Pushes a timestamp-versioned template to Coder. |
| `just tunnel` | Creates a secure bridge for localhost-to-cloud networking. |
| `just build` | Standalone Terraform deployment (CLI Only). |
| `just stop` / `just start` | Pause/Resume the workspace instance. |
| `just destroy-dangerously` | Wipes the entire environment, including persistent disks. |

---

## 📁 Repository Structure

- `modules/coder-server/`: Permanent Coder control plane infrastructure.
- `modules/aws/`: Workspace infrastructure definitions (VPC, IAM, EC2, S3).
- `setup.sh`: The "Universal Provisioner" that installs the toolchain.
- `nexus_wizard.py`: Interactive configuration and secret handler.
- `scripts/verify_server.sh`: Automated health validation for hosted servers.
- `specs/`: Technical specifications for the entire system.
