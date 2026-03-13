# Toolchain Specifications: Nexus-Cloud AI Workspace

## Unified AI Toolchain
1. **Gemini CLI**: NPM-based install.
2. **Claude Code**: NPM-based install.
3. **OpenCode**: NPM-based install.
4. **Aider**: UV-based tool install.
5. **LLM**: UV-based tool install with Anthropic/Gemini plugins.

## Provisioning Automation
* **Non-Interactive Mandate**: All installations must use `-y` or `--disable-prompts` flags.
* **Privilege Level**: Scripts must be executed with `sudo -E` to preserve critical environment variables (e.g., `DEBIAN_FRONTEND=noninteractive`).
* **Path Management**:
    - **UV**: Must source `$HOME/.local/bin/env` or explicitly path to `/root/.local/bin` when run as root.
    - **GCloud**: Must specify `--install-dir` and export `CLOUDSDK_CORE_DISABLE_PROMPTS=1`.
* **Reliability**: Scripts are injected via **Base64** in `user_data` to ensure zero corruption during delivery.

## Developer & System Tools
- **Runtimes**: Node.js (v20+), Go, Python 3.10+.
- **Containers**: Docker (pre-configured with user group access).
- **Identity**: Git global config (`user.name`, `user.email`) automated via wizard.
