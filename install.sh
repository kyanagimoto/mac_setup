#!/usr/bin/env bash
set -euo pipefail

echo "=== mac_setup: Homebrew + Brewfile + Colima + zsh installer ==="

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Load Homebrew environment for current shell (works on Apple Silicon and Intel)
  if [[ -d /opt/homebrew/bin ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    # On some older systems brew may be under /usr/local
    if [[ -x "/usr/local/bin/brew" ]]; then
      eval "$(/usr/local/bin/brew shellenv)" || true
    fi
  fi
fi

echo "Updating Homebrew..."
brew update || true

# Ensure brew-bundle is available
if ! brew help bundle >/dev/null 2>&1; then
  echo "Installing brew-bundle (part of homebrew/bundle)..."
  brew tap homebrew/bundle || true
fi

if [[ -f Brewfile ]]; then
  echo "Installing packages from Brewfile..."
  brew bundle --file=Brewfile || {
    echo "brew bundle reported errors. You can retry manually with 'brew bundle --file=Brewfile'"
    exit 1
  }
else
  echo "No Brewfile found in repo root. Skipping brew bundle."
fi

echo "Running brew cleanup..."
brew cleanup || true

# ============================================================================
# Setup Colima configuration and auto-start
# ============================================================================

echo ""
echo "=== Setting up Colima ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLIMA_CONFIG="${HOME}/.colima/default.yaml"
COLIMA_CONFIG_SOURCE="${SCRIPT_DIR}/colima.yaml"

# Create ~/.colima directory if it doesn't exist
mkdir -p "${HOME}/.colima"

# Copy colima config if present in the repo
if [[ -f "${COLIMA_CONFIG_SOURCE}" ]]; then
  echo "Copying colima configuration to ${COLIMA_CONFIG}..."
  cp "${COLIMA_CONFIG_SOURCE}" "${COLIMA_CONFIG}"
else
  echo "Warning: colima.yaml not found in repo root. Using default colima configuration."
fi

# Setup LaunchAgent for auto-start on macOS boot
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
mkdir -p "${LAUNCH_AGENTS_DIR}"

PLIST_FILE="${LAUNCH_AGENTS_DIR}/com.mac-setup.colima.plist"

cat > "${PLIST_FILE}" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mac-setup.colima</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>-c</string>
        <string>sleep 10 &amp;&amp; /opt/homebrew/bin/colima start --profile default || /usr/local/bin/colima start --profile default</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>60</integer>
    <key>StandardErrorPath</key>
    <string>/var/log/colima.log</string>
    <key>StandardOutPath</key>
    <string>/var/log/colima.log</string>
</dict>
</plist>
PLIST

echo "Created LaunchAgent at ${PLIST_FILE}"
echo "Colima will auto-start on next macOS boot"

# Load the LaunchAgent immediately
launchctl load "${PLIST_FILE}" 2>/dev/null || {
  echo "Note: LaunchAgent will be loaded on next system restart"
}

# ============================================================================
# Setup zsh configuration
# ============================================================================

echo ""
echo "=== Setting up zsh configuration ==="

ZSHRC_FILE="${HOME}/.zshrc"
ZSHRC_SOURCE="${SCRIPT_DIR}/.zshrc"

# Backup existing .zshrc if it exists
if [[ -f "${ZSHRC_FILE}" ]]; then
  BACKUP_FILE="${ZSHRC_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "Backing up existing .zshrc to ${BACKUP_FILE}..."
  cp "${ZSHRC_FILE}" "${BACKUP_FILE}"
fi

# Copy new .zshrc from repo
if [[ -f "${ZSHRC_SOURCE}" ]]; then
  echo "Copying zsh configuration to ${ZSHRC_FILE}..."
  cp "${ZSHRC_SOURCE}" "${ZSHRC_FILE}"
  chmod 644 "${ZSHRC_FILE}"
  echo "[OK] zsh configuration installed"
else
  echo "Warning: .zshrc not found in repo root. Skipping zsh configuration."
fi

# ============================================================================
# Install optional tools
# ============================================================================

echo ""
echo "=== Installing optional tools ==="

# Install starship (modern shell prompt)
if ! command -v starship &> /dev/null; then
  echo "Installing starship..."
  brew install starship
  echo "[OK] starship installed"
else
  echo "[OK] starship already installed"
fi

# Install nvm (Node Version Manager) if not present
if [[ ! -d "${HOME}/.nvm" ]]; then
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
  export NVM_DIR="${HOME}/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  echo "[OK] nvm installed"
else
  echo "[OK] nvm already installed"
fi

# ============================================================================
# Final Summary
# ============================================================================

cat <<'NOTE'

[COMPLETE] Installation complete!

=== What was installed ===
- Homebrew packages (from Brewfile)
- Colima with k3s (auto-starts on boot)
- Comprehensive zsh configuration with:
  * Homebrew environment setup
  * kubectl completion & Kubernetes aliases
  * Docker & Colima aliases
  * Git aliases & shortcuts
  * Starship prompt integration
  * NVM (Node Version Manager)
  * GitHub Copilot CLI
  * Useful functions (dockerclean, kctx, kgetlogs, etc.)

=== Next Steps ===
1. Reload your shell:
   source ~/.zshrc

2. (Optional) Install Starship config:
   mkdir -p ~/.config/starship
   touch ~/.config/starship.toml

3. Check installed tools:
   brew list
   kubectl version --client
   colima status
  copilot --version

=== Useful Commands ===
Colima:
  colima start        # Start Colima
  colima stop         # Stop Colima
  colima status       # Check status
  colima-start        # Alias for colima start

Kubernetes:
  k get pods          # List pods
  k get svc           # List services
  kctx                # Show current context
  kctx <name>         # Switch context

Docker:
  d ps                # List containers
  d images            # List images
  dockerclean         # Clean up Docker

GitHub Copilot CLI:
  copilot             # Start Copilot in the current directory
  /login              # Authenticate on first launch (run inside Copilot)

=== Notes ===
- Your old .zshrc was backed up (if it existed)
- Colima will auto-start on macOS boot
- Colima logs: tail -f /var/log/colima.log
- LaunchAgent status: launchctl list | grep colima

Enjoy your development setup!

NOTE
