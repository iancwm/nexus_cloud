# Infrastructure Specifications: Nexus-Cloud AI Workspace

## Orchestration Layer
* **Tool:** Terraform & Coder (Open Source).
* **Architecture:** Decoupled (Ephemeral Compute vs. Persistent Data).

## Connectivity & Networking
* **Tunneling**: Utilizes Cloudflare Tunnels (`just tunnel`) to bridge local Coder servers (127.0.0.1) to the public internet.
* **Access URL**: The tunnel URL must be passed to Coder as the `--access-url` to enable remote agents to "phone home."

## Observability & Logging
* **Real-time Streaming**: To ensure logs appear in the Coder dashboard, the primary provisioner (`setup.sh`) must be executed within the `coder_agent`'s `startup_script`.
* **Execution Pattern**: "Write-then-Execute" — `user_data` writes scripts to disk (Base64 encoded), and the `coder_agent` triggers them upon connection.
* **Timeouts**: `startup_script_timeout` is set to 1800s (30m) to accommodate full toolchain installation.

## Resource Requirements
* **Root Storage**: Minimum 30GB `root_block_device` required to accommodate multiple Cloud SDKs (AWS, GCloud, Azure) and Docker images.
* **Instance Type**: Minimum `t3.large` (2 vCPU, 8GB RAM) recommended for stable concurrent AI CLI performance.

## Coder Integration & Automation
* **Agent Token Injection**: The `CODER_AGENT_TOKEN` must be explicitly exported in EC2 `user_data` before executing the `init_script`.
* **Unique Identity**: `nexus-${var.user_id}-${var.workspace_name}` prefix ensures unique global resource names (IAM, VPC) per workspace.

## Persistence & Disaster Recovery
* **EBS**: 20GB persistent volume for user data.
* **S3 Snapshots**: Automated backup of identity volume on shutdown via `sync_identity.sh`.
