# Infrastructure Specifications: Nexus-Cloud AI Workspace

## Orchestration Layer
* **Tool:** Terraform & Coder (Open Source).
* **Architecture:** Decoupled (Ephemeral Compute vs. Persistent Data).

## Coder Integration
* **Parameters**: `instance_type` is managed via `data.coder_parameter` for interactive UI overrides.
* **Agent**: `coder_agent` handles the startup lifecycle and triggers `setup.sh`.
* **Metadata**: Real-time Public IP and status reporting in the Coder dashboard.

## IAM-First Authentication (Zero-Touch)
* **AWS**: IAM Instance Profile grants EC2 permissions for S3 (Identity Backup) and Secrets Manager (AI Keys & Git).
* **Compliance**: Full IMDSv2 support for secure metadata access.

## Dual-Layer Persistence
* **EBS**: 20GB persistent volume with `lifecycle { prevent_destroy = true }`.
* **S3 Backup**: Automatic snapshots of `/mnt/persistent_config` on shutdown via `sync_identity.sh` and `systemd`.

## Automation & Portability
* **Justfile**: Unified CLI for building, stopping, and remote provisioning.
* **SSH Detection**: Smart local key discovery (`id_nexus-cloud-project`, `id_ed25519`, `id_rsa`) for one-command deployment.
