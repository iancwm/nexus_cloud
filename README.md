# ☁️ Nexus-Cloud AI Workspace

A **zero-footprint** Infrastructure-as-Code (IaC) repository that provisions a persistent, high-performance coding environment for terminal-based AI agents.

## 🛡 Security & Permissions

### ⚠️ IMPORTANT: Cloud CLI Configuration
*   **ADMIN RIGHTS REQUIRED:** Ensure your Cloud Provider's CLI (e.g., `aws`) is configured with an **ADMIN ACCOUNT**. Provisioning Infrastructure (IAM Roles, VPCs, Secrets) requires full administrative privileges. 
*   **NO MANUAL MODIFICATIONS:** For the safety of your environment, **never modify Terraform state or configuration files manually**. Use the `just wizard` or `just` commands to manage all aspects of your workspace. Manual edits can cause irreversible data loss or broken infrastructure.

---

## 🚀 Quick Start


Deploy your entire workspace with three simple steps:

1. **Run the Setup Wizard**:
   ```bash
   just wizard
   ```
   *Follow the interactive prompts to configure your AWS region and AI API keys. The wizard will securely upload your keys to AWS Secrets Manager.*

2. **Verify Setup**:
   ```bash
   just debug
   ```
   *This runs a diagnostic check to ensure all dependencies are installed and your AWS connection is healthy.*

3. **Build Workspace**:
   ```bash
   just build AMI=ami-0c7217cdde317cfec INSTANCE_TYPE=t3.large
   ```
3. **Connect & Setup**:
   ```bash
   ssh ubuntu@$(just status | grep public_ip)
   ./setup.sh
   ```

---

## 🏗 Key Features

- **Zero-Touch Identity**: No local credentials stored. API keys are fetched from **AWS Secrets Manager** via **IAM Instance Profiles**.
- **Dual-Layer Persistence**: Standard config paths (`~/.config`) are symlinked to a persistent 20GB EBS volume that survives instance destruction.
- **Cross-Instance Recovery**: Automatic **S3 Identity Snapshots** on shutdown; seamless restoration on boot via `systemd`.
- **Fast Toolchain**: Pre-configured with `uv` for lightning-fast installation of AI CLIs (Claude, Gemini, LLM).

---

## 🔧 Automation (`justfile`)

| Command | Description |
| :--- | :--- |
| `just init` | Initialize Terraform and Python environments. |
| `just secrets <ant> <open> <gem>` | Securely upload API keys to AWS. |
| `just build` | Provision AWS VPC, EC2, EBS, and IAM. |
| `just plan` | Preview infrastructure changes. |
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
- `manage_secrets.py`: Local secure secret handler.
- `specs/`: Technical specifications for infrastructure and toolchain.
