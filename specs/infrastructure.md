# Infrastructure Specifications: Nexus-Cloud AI Workspace

## Orchestration Layer
* **Tool:** Terraform
* **Architecture:** Decoupled (Ephemeral vs. Persistent Layers)

## Infrastructure Components
* **Compute:** VMs (AWS, GCP, or Azure)
* **Networking:** VPCs
* **Persistent Storage:** Disks (EBS, Persistent Disk, Managed Disk) and Buckets (S3, GCS, Blob Storage)

## IAM-First Authentication (Zero-Touch)
* **Strategy:** Minimize manual credential handling.
* **Mechanism:** 
  * **AWS:** Assign IAM Instance Profile to EC2 with permissions for S3 (Identity Backup) and Secrets Manager (AI API Keys).
  * **GCP:** Use Workload Identity / Service Account attachment.
  * **Azure:** Managed Identities for system-assigned access to Blob and Key Vault.

## Cloud Secret Management
* **Storage:** API Keys (Anthropic, OpenAI) and sensitive configs stored in AWS Secrets Manager, GCP Secret Manager, or Azure Key Vault.
* **Retrieval:** `setup.sh` fetches secrets at runtime using the instance's IAM identity, avoiding local `config.yaml` storage where possible.

## Dual-Layer Persistence (The "Never Logout" System)
* **Strategy:** Secondary disk mounted to `/mnt/persistent_config`.
* **Symlinking:** Standard config paths (e.g., `~/.config/claude-code`) are symlinked to this volume by `setup.sh`.
* **Lifecycle:** `lifecycle { prevent_destroy = true }` must be set on persistent disk resources in Terraform.

## Disaster Recovery (Cross-Cloud Identity)
* **Identity Snapshot:** Sync `/mnt/persistent_config` to S3/GCS/Blob bucket.
* **Mechanism:** `sync_config.sh` script using `systemd` hooks.
* **Boot Hook:** Pull latest snapshot from bucket if persistent disk is new/empty.
* **Shutdown Hook:** Sync to bucket on shutdown.
