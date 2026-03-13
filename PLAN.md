# Implementation Plan: Nexus-Cloud AI Workspace

## Phase 1: AWS Infrastructure (Priority) [COMPLETE]
* [x] **1.1. IAM Identity & Roles**: IAM Instance Profile with Secrets Manager/S3 access.
* [x] **1.2. Secrets Manager**: Established for AI API Keys.
* [x] **1.3. S3 Bucket**: Provisioned for identity snapshots.
* [x] **1.4. Terraform Module**: Core VPC, EC2, and Persistent EBS.

## Phase 2: Zero-Touch Toolchain & Secrets [COMPLETE]
* [x] **2.1. `setup.sh` Automation**: Cloud detection and toolchain installation via `uv`.
* [x] **2.2. Secret Retrieval**: IAM-driven retrieval from AWS Secrets Manager.
* [x] **2.3. Symlinking**: Identity persistence via `/mnt/persistent_config`.

## Phase 3: Disaster Recovery [COMPLETE]
* [x] **3.1. `sync_identity.sh`**: Dynamic S3 sync logic for persistent volumes.
* [x] **3.2. System Integration**: `nexus-sync.service` for automated backup/restore.

## Phase 4: Automation & Refinement [COMPLETE]
* [x] **4.1. Justfile Automation**: `build`, `tear-down`, and `secrets` recipes.
* [x] **4.2. Package Management**: `uv` integrated for local and remote management.
* [x] **4.3. Repository Cleanup**: Removed redundant specs and empty modules.
* [x] **4.4. Documentation**: Comprehensive README.md.

## Phase 5: Lifecycle & Portability [COMPLETE]
* [x] **5.1. Smart Key Detection**: Automated `SSH_PUB` discovery in `justfile`.
* [x] **5.2. Pause/Resume**: Added `just stop` and `just start` commands.
* [x] **5.3. Full Cleanup**: Added `just destroy-dangerously` to bypass safety locks.
* [x] **5.4. Coder Integration**: Coder-ready template with Agent and Provider support.

---

## Success Criteria
1. [x] Zero-touch IAM identity (no manual keys on disk).
2. [x] Persistent identity volume across instance lifecycles.
3. [x] Automated S3 disaster recovery snapshots.
4. [x] High-performance toolchain via `uv`.
5. [x] Single-command setup for new machines.
