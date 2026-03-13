# Nexus-Cloud Setup Wizard & Debugger Specifications

## Objective
To provide an interactive CLI tool that guides users through the initial configuration of the `nexus-cloud` workspace and detects common setup errors.

## Core Features
1. **Interactive Setup Wizard**:
   - Collect AWS credentials (Access Key, Secret Key, Region).
   - Collect AI API keys (Anthropic, OpenAI, Gemini).
   - Validate input format (regex check for keys).
   - Generate `config.yaml` for local reference and upload keys to AWS Secrets Manager.
2. **Setup Debugger**:
   - Dependency check: Verify `terraform`, `uv`, `just`, `aws` are installed.
   - Connectivity check: Verify AWS credentials can call `sts:GetCallerIdentity`.
   - Secret check: Verify if `nexus-cloud/ai-api-keys` exists in Secrets Manager.
   - Resource check: Verify if an instance is currently running (`terraform state`).
3. **Helpful Dialogue**:
   - Provide tips for each step (e.g., "Leave blank for Pro subscription mode").
   - Offer troubleshooting steps for failed checks.

## Implementation Details
- **Language**: Python (using `click` and `boto3`).
- **Tooling**: Integrated with `uv` and `just`.
- **Primary Script**: `nexus_wizard.py`.
- **Justfile Integration**: Add `just wizard` and `just debug`.
