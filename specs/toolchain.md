# Toolchain Specifications: Nexus-Cloud AI Workspace

## Unified AI Toolchain
The environment must come pre-installed with:
1. **Gemini CLI**: Authenticated via `GOOGLE_APPLICATION_CREDENTIALS` (Service Account/Identity).
2. **Claude Code**: Prioritize Anthropic Subscription/Managed Token.
3. **Codex/OpenCode**: OpenAI account limits.
4. **Cloud SDKs**: Pre-authenticated via IAM Instance Profile (no `aws configure` needed).

## Zero-Touch Auth Logic
* **Goal:** Zero manual input beyond initial infrastructure setup.
* **Mechanism:**
  * `setup.sh` queries the cloud's **Metadata Service** or **Secret Manager** to retrieve API keys.
  * If `ANTHROPIC_API_KEY` exists in the cloud secret manager, it is exported to `.bashrc`.
  * For Subscription-based CLI usage, utilize **Device Code Flow** (OAuth) stored in the persistent `/mnt/persistent_config`.
* **Credential Hierarchy:** IAM Profile (Identity) > Cloud Secrets > Local `config.yaml` (Fallback).

## Setup Script (`setup.sh`)
* **Detection:** Detect cloud environment and **IAM Role/Identity**.
* **Installation:** Install required CLIs and SDKs.
* **Secret Retrieval:** Use `aws secretsmanager`, `gcloud secrets`, or `az keyvault` to fetch configuration secrets using the instance's identity.
* **Configuration:** Symlink standard config paths to `/mnt/persistent_config`.
