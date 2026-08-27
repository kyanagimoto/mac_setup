# Copilot Instructions for mac_setup

## Repository Overview

**mac_setup** is a macOS development environment automation project that bootstraps a complete developer setup with Homebrew, Docker/Colima, Kubernetes (k3s), and shell configuration. The project provides both an automated installation script and modular configuration files for reproducible setups.

## Build, Test & Validation

### Installation & Verification
```bash
# Make the install script executable
chmod +x install.sh

# Run the installer (installs Homebrew, packages, Colima, zsh config)
./install.sh

# Reload shell after installation
source ~/.zshrc

# Verify installations
brew list                    # Check installed packages
colima status               # Verify Colima/k3s is running
kubectl version --client    # Check Kubernetes setup
copilot --version          # Check Copilot CLI
```

### Checking Colima Logs
```bash
tail -f /var/log/colima.log  # Monitor auto-start on boot
```

## Architecture & Key Components

### Core Files & Their Responsibilities

**Brewfile** - Package manifest
- Defines all Homebrew packages and casks to install (Git, Node.js, Python, kubectl, Docker, Colima, iTerm2, VS Code, Copilot CLI)
- Install packages by running `brew bundle --file=Brewfile`

**install.sh** - Main orchestrator script
- Installs Homebrew if missing (auto-detects Apple Silicon vs Intel)
- Runs `brew bundle` to install packages from Brewfile
- Copies `colima.yaml` to Colima's template for new instances (`~/.colima/_templates/default.yaml`, resolved via `colima template --print`), backing up any existing template
- Creates LaunchAgent (`com.mac-setup.colima.plist`) to auto-start Colima on macOS boot
- Backs up existing `.zshrc` before copying new one
- Installs optional tools: nvm (Node Version Manager)

**.zshrc** - Comprehensive shell configuration
- Homebrew environment setup (handles both Apple Silicon `/opt/homebrew` and Intel `/usr/local`)
- NVM (Node Version Manager) integration
- Kubernetes/kubectl completion and aliases (`k`, `kgp`, `kgs`, `kgn`, `kdesc`, `klogs`)
- Colima aliases (`colima-start`, `colima-stop`, `colima-status`)
- Docker aliases (`d`, `dc`, `di`, `dps`)
- Git aliases (`gs`, `ga`, `gc`, `gp`, `gl`, `gb`, `gco`)
- Utility functions: `dockerclean()`, `kctx()`, `kgetlogs()`
- Custom prompt with git branch display
- macOS-specific aliases (`hidefiles`, `showfiles`)

### colima.yaml
- Located in repo root, copied to Colima's new-instance template during installation
- Configures Colima runtime: CPU cores, memory, disk size, Kubernetes version
- Host-specific fields (`arch`, `vmType`, `mountType`) are deliberately omitted so Colima picks per-machine values
- Applies to newly created instances only; an existing instance needs `colima delete && colima start` or `colima start --edit`
- Colima defaults are used if the file is absent

### LaunchAgent (macOS auto-start)
- **File**: `~/Library/LaunchAgents/com.mac-setup.colima.plist`
- **Created by**: install.sh
- **Function**: Auto-starts Colima 10 seconds after macOS boot
- **Logs to**: `/var/log/colima.log`
- Runs every 60 seconds; only starts if not already running

## Key Conventions

### Shell Aliases as Quick Access
The `.zshrc` defines comprehensive aliases grouped by tool (Kubernetes, Docker, Git). When updating aliases:
- Keep them organized in logical sections with comments (e.g., `# Kubernetes aliases`)
- Use single-letter or minimal abbreviations for frequent commands (`k` for kubectl, `g` for git)
- Prefix related aliases with the same letter when possible

### Brewfile Structure
- Organize packages by category: core tools, utilities, containers, GUI apps
- Use `brew` for CLI tools, `cask` for GUI applications
- Avoid hard-coding version constraints; let Homebrew manage updates
- Comment out optional entries that require additional setup (e.g., `mas` for App Store apps)

### Backup & Non-Destructive Installation
- The install.sh script backs up existing `.zshrc` with timestamp: `.zshrc.backup.YYYYMMDD_HHMMSS`
- LaunchAgent creation is idempotent—can be re-run safely
- Uses conditional checks (`if [[ -f ... ]]`) before file operations

### Error Handling & Logging
- install.sh uses `set -euo pipefail` for strict error handling
- Provides feedback messages for each step
- Colima logs to `/var/log/colima.log` instead of stdout
- LaunchAgent runs silently; check logs if auto-start fails

### Platform Compatibility
- Detects macOS architecture: Apple Silicon (`/opt/homebrew/bin`) vs Intel (`/usr/local/bin`)
- Both architectures handled in Homebrew setup, NVM config, and LaunchAgent
- Colima binary location varies; LaunchAgent tries both paths

## Development Guidelines for Changes

### Adding New Packages
1. Add to **Brewfile** under appropriate category
2. If it requires shell setup, add configuration to **.zshrc**
3. Test with: `chmod +x install.sh && ./install.sh`
4. Verify the tool is accessible: `command -v <tool>` or `<tool> --version`

### Updating Shell Aliases or Functions
1. Edit **.zshrc** within the appropriate section
2. Reload: `source ~/.zshrc` or open new terminal
3. Test the alias/function: `<alias> [args]`

### Modifying Colima Configuration
1. Edit **colima.yaml** in repo root
2. Update comments in **install.sh** if defaults change
3. Re-run `./install.sh` to deploy the template, then recreate the instance (`colima delete && colima start`) to apply it
4. Test: `colima status` and `kubectl get nodes`

### LaunchAgent Debugging
- Check status: `launchctl list | grep colima`
- Unload: `launchctl unload ~/Library/LaunchAgents/com.mac-setup.colima.plist`
- Reload: `launchctl load ~/Library/LaunchAgents/com.mac-setup.colima.plist`
- Logs: `tail -f /var/log/colima.log`

## Important Notes

- **No tests or linting**: This is a configuration/setup project; validation is via manual verification of installed tools
- **Idempotent design**: The install.sh script can be re-run safely (uses conditional checks and backups)
- **Language**: README and comments are in Japanese; keep codebase consistent with existing language patterns
- **README as source of truth**: README.md documents user-facing features and troubleshooting; keep it synchronized with any changes
