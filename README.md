# ☁️ Nexus-Cloud AI Workspace

A **zero-footprint** Infrastructure-as-Code (IaC) repository that provisions a persistent, high-performance coding environment for terminal-based AI agents.

## 🛡 Security & Permissions

### ⚠️ IMPORTANT: Cloud CLI Configuration
*   **ADMIN RIGHTS REQUIRED:** Ensure your Cloud Provider's CLI (e.g., `aws`) is configured with an **ADMIN ACCOUNT**. Provisioning Infrastructure (IAM Roles, VPCs, Secrets) requires full administrative privileges. 
*   **NO MANUAL MODIFICATIONS:** For the safety of your environment, **never modify Terraform state or configuration files manually**. Use the `just wizard` or `just` commands to manage all aspects of your workspace. Manual edits can cause irreversible data loss or broken infrastructure.

---

## 🚀 Quick Start

### Option A: Standalone Deployment
Deploy your entire workspace with three simple steps:

1. **Run the Setup Wizard**:
   ```bash
   just wizard
   ```
   *Follow the interactive prompts to configure your AWS region, AI API keys, and Git identity.*

2. **Verify Setup**:
   ```bash
   just debug
   ```

3. **Build & Provision**:
   ```bash
   just build
   just setup-remote
   ```

### Option B: Coder Deployment (Dashboard)
1. **Login to Coder**: `coder login <url>`
2. **Create Template**: `coder templates create nexus-cloud`
3. **Provision**: Create a workspace from the Coder UI. All tools and Git will be configured automatically.

---

## 🏗 Key Features

- **Zero-Touch Identity**: No local credentials stored. API keys are fetched from **AWS Secrets Manager** via **IAM Instance Profiles**.
- **Dual-Layer Persistence**: Standard config paths (`~/.config`) are symlinked to a persistent 20GB EBS volume that survives instance destruction.
- **Cross-Instance Recovery**: Automatic **S3 Identity Snapshots** on shutdown; seamless restoration on boot via `systemd`.
- **Expanded Toolchain**: Pre-configured with `uv`, `llm`, `aider`, `docker`, `node`, `go`, and all major cloud SDKs (`aws`, `gcloud`, `az`).
- **Immediate Git Setup**: Git identity configured out-of-the-box via the setup wizard.
- **Coder Native**: Designed to run as a Coder template for a seamless dashboard experience.

---

## 🔧 Automation (`justfile`)

| Command | Description |
| :--- | :--- |
| `just wizard` | Guided interactive setup for all keys and identity. |
| `just build` | Provision AWS VPC, EC2, EBS, and IAM. |
| `just setup-remote` | Remote execution of the provisioner on the instance. |
| `just ssh` | Instant connection to your workspace. |
| `just stop` | Pause the workspace (Stop instance, keep disk). |
| `just start` | Resume the workspace. |
| `just tear-down` | Destroy the environment (persists data in EBS/S3). |

---

## 🛡 Security Architecture

- **IAM-First**: Principle of least privilege enforced via dedicated EC2 Instance Profiles.
- **Credential Protection**: Sensitive keys never touch the local disk in plaintext.
- **Data Integrity**: `lifecycle { prevent_destroy = true }` protects your EBS identity volume.

---

## 📁 Repository Structure

- `modules/aws/`: Core infrastructure definitions.
- `setup.sh`: Automated environment provisioner (remote).
- `sync_identity.sh`: S3 synchronization utility (remote).
- `nexus_wizard.py`: Interactive configuration handler.
- `specs/`: Technical specifications for infrastructure and toolchain.
