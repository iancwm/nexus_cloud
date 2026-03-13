# Infrastructure Specifications: Nexus-Cloud AI Workspace

## Orchestration Layer
* **Tool:** Terraform & Coder
* **Architecture:** Decoupled (Ephemeral vs. Persistent Layers)

## IAM-First Authentication (Zero-Touch)
* **Strategy:** Minimize manual credential handling.
* **Mechanism:** 
  * **AWS:** IAM Instance Profile grants EC2 permissions for S3 (Identity Backup) and Secrets Manager (AI API Keys).
  * **Zero-Touch Logic:** No manual `aws configure`. Identity is assigned at the resource level.

## Cloud Secret Management
* **Storage:** API Keys (Anthropic, OpenAI, Gemini) stored in AWS Secrets Manager.
* **Retrieval:** `setup.sh` fetches secrets at runtime using the instance's IAM identity.
* **Automation:** `manage_secrets.py` (via `just secrets`) handles local-to-cloud secret synchronization.

## Dual-Layer Persistence (The "Never Logout" System)
* **Strategy:** 20GB EBS Volume mounted to `/mnt/persistent_config`.
* **Symlinking:** Standard paths (e.g., `~/.config`) symlinked to this volume.
* **Lifecycle:** `lifecycle { prevent_destroy = true }` enforced on EBS to prevent accidental data loss.

## Disaster Recovery (Cross-Cloud Identity)
* **Identity Snapshot:** Sync `/mnt/persistent_config` to S3 bucket.
* **Mechanism:** `sync_identity.sh` script with dynamic bucket discovery.
* **Hooks:** Systemd `nexus-sync.service` triggers `pull` on boot and `push` on shutdown.

## Automation & Portability
* **Justfile:** Unified interface for all lifecycle operations (`build`, `stop`, `start`, `destroy-dangerously`).
* **Smart Detection:** Automatic SSH public key discovery for seamless multi-machine deployment.
