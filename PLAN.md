# Implementation Plan: Nexus-Cloud AI Workspace

## Phase 1: AWS Infrastructure (Priority) [COMPLETE]
* [x] **1.1. IAM Identity & Roles**: IAM Instance Profile with Secrets Manager/S3 access.
* [x] **1.2. Secrets Manager**: Idempotent secret handling with root module import.
* [x] **1.3. S3 Bucket**: Provisioned for identity snapshots.
* [x] **1.4. Terraform Module**: Core VPC, EC2, and Persistent EBS.

## Phase 2: Zero-Touch Toolchain & Secrets [COMPLETE]
* [x] **2.1. `setup.sh` Automation**: Cloud detection (IMDSv2) and toolchain installation via `uv`.
* [x] **2.2. Secret Retrieval**: IAM-driven retrieval from AWS Secrets Manager.
* [x] **2.3. Symlinking**: Identity persistence via `/mnt/persistent_config`.

## Phase 3: Disaster Recovery [COMPLETE]
* [x] **3.1. `sync_identity.sh`**: Dynamic S3 sync logic with IMDSv2 support.
* [x] **3.2. System Integration**: `nexus-sync.service` for automated backup/restore.

## Phase 4: Automation & Refinement [COMPLETE]
* [x] **4.1. Justfile Automation**: `build`, `setup-remote`, `ssh`, and `stop`/`start` recipes.
* [x] **4.2. Package Management**: `uv` integrated for local and remote management.
* [x] **4.3. Setup Wizard**: Interactive `just wizard` for configuration.
* [x] **4.4. Debugger**: Diagnostic suite for environment health.

## Phase 5: Lifecycle & Portability [COMPLETE]
* [x] **5.1. Smart Key Detection**: Automated `SSH_PUB` discovery in `justfile`.
* [x] **5.2. Pause/Resume**: Added `just stop` and `just start` commands.
* [x] **5.3. Full Cleanup**: Added `just destroy-dangerously` to bypass safety locks.
* [x] **5.4. Coder Integration**: Coder-ready template with Agent and Provider support.

## Phase 6: Setup Wizard & Debugger [COMPLETE]
* [x] **6.1. Interactive CLI**: Implement `nexus_wizard.py` using `click`.
* [x] **6.2. Debugger Utility**: Add diagnostic checks for dependencies and AWS connectivity.
* [x] **6.3. Justfile Integration**: Add `just wizard` and `just debug` recipes.
* [x] **6.4. Documentation**: Update README with wizard/debugger instructions.

## Phase 7: Productivity Expansion [COMPLETE]
* [x] **7.1. Git Configuration**: Wizard collects Git identity and `setup.sh` configures it.
* [x] **7.2. Expanded Toolchain**: Added `aider`, `docker`, `claude`, `opencode`, `gcloud`, `az`.
* [x] **7.3. Stability**: Fixed `uv` paths, system dependencies (`unzip`, `jq`), and Coder parameter syntax.

## Phase 8: Coder Template Finalization [COMPLETE]
* [x] **8.1. Refine Coder Parameters**: Added interactive `instance_type` and `ebs_size` parameters.
* [x] **8.2. Automate Script Bundling**: Refined `coder_agent` startup script for bundled script support.
* [x] **8.3. Unified Coder Workflow**: Added `just coder-push` for template management.

---

## Success Criteria
1. [x] Zero-touch IAM identity (no manual keys on disk).
2. [x] Persistent identity volume across instance lifecycles.
3. [x] Automated S3 disaster recovery snapshots.
4. [x] High-performance toolchain via `uv`.
5. [x] VS Code Remote-SSH ready architecture.
6. [x] Interactive setup wizard and automated error detection.
7. [x] Complete CLI suite and Git configured out-of-the-box.
8. [x] Seamless Coder-driven deployment via the dashboard.
