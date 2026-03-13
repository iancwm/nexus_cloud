# Toolchain Specifications: Nexus-Cloud AI Workspace

## Unified AI Toolchain
The environment comes pre-installed with a high-performance terminal-based AI suite:
1. **Gemini CLI**: Authenticated via `GOOGLE_APPLICATION_CREDENTIALS`.
2. **Claude Code**: Official Anthropic CLI for agentic coding.
3. **OpenCode**: Open-source agentic terminal for universal model access.
4. **Aider**: AI pair-programming tool integrated with Git.
5. **LLM**: CLI utility for interacting with various LLMs (Anthropic, OpenAI, Gemini plugins).
6. **Cloud SDKs**: Fully authenticated `aws`, `gcloud`, and `az` CLIs.

## Developer & System Tools
- **Runtimes**: Node.js (v20+), Go, Python 3.10+.
- **Containers**: Docker (pre-configured with user group access).
- **Automation**: `just` and `uv` for high-performance package management.
- **Git**: Global configuration for `user.name` and `user.email`.

## Zero-Touch Auth & Config
- **Identity Retrieval**: `setup.sh` fetches API keys and Git identity from AWS Secrets Manager at runtime.
- **Persistent Symlinking**: `$HOME/.config` and tool-specific paths are mapped to `/mnt/persistent_config`.
- **IMDSv2 Support**: Full compatibility with modern AWS metadata security for region and identity discovery.
