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
# Setup VS Code extensions and settings
# ============================================================================

echo ""
echo "=== Setting up VS Code ==="

if command -v code &> /dev/null; then
  code --install-extension vscodevim.vim --force
  code --install-extension Continue.continue --force
  echo "[OK] VS Code extensions installed"
else
  echo "Warning: VS Code CLI (code) not found. Skipping extension installation."
  echo "Install VS Code first, then run: code --install-extension Continue.continue"
fi

# ============================================================================
# Setup Continue configuration
# ============================================================================

echo ""
echo "=== Setting up Continue configuration ==="

CONTINUE_CONFIG_DIR="${HOME}/.continue"
CONTINUE_CONFIG_FILE="${CONTINUE_CONFIG_DIR}/config.yaml"
CONTINUE_CONFIG_SOURCE="${SCRIPT_DIR}/continue/continue.config.yaml"

if [[ -f "${CONTINUE_CONFIG_SOURCE}" ]]; then
  mkdir -p "${CONTINUE_CONFIG_DIR}"

  if [[ -f "${CONTINUE_CONFIG_FILE}" ]]; then
    BACKUP_FILE="${CONTINUE_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up existing Continue config to ${BACKUP_FILE}..."
    cp "${CONTINUE_CONFIG_FILE}" "${BACKUP_FILE}"
  fi

  echo "Copying Continue configuration to ${CONTINUE_CONFIG_FILE}..."
  cp "${CONTINUE_CONFIG_SOURCE}" "${CONTINUE_CONFIG_FILE}"
  echo "[OK] Continue configuration installed"
else
  echo "Warning: continue/continue.config.yaml not found in repo root. Skipping Continue configuration."
fi

# ============================================================================
# Setup Neovim / Vim configuration
# ============================================================================

echo ""
echo "=== Setting up Neovim / Vim ==="

# Install neovim, fzf, ripgrep via Homebrew if missing
for pkg in neovim fzf ripgrep; do
  if ! brew list "${pkg}" &>/dev/null; then
    echo "Installing ${pkg}..."
    brew install "${pkg}"
  else
    echo "[OK] ${pkg} already installed"
  fi
done

# Install fzf shell key bindings/fuzzy completion (non-destructive, no rc edits)
FZF_PREFIX="$(brew --prefix fzf 2>/dev/null || true)"
if [[ -n "${FZF_PREFIX}" && -x "${FZF_PREFIX}/install" ]]; then
  "${FZF_PREFIX}/install" --key-bindings --completion --no-update-rc --no-bash --no-fish || true
fi

VIMRC_SOURCE="${SCRIPT_DIR}/vim/vimrc"

if [[ -f "${VIMRC_SOURCE}" ]]; then
  # --- Vim ---
  echo "Configuring Vim (~/.vimrc)..."
  if [[ -f "${HOME}/.vimrc" ]]; then
    cp "${HOME}/.vimrc" "${HOME}/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
  fi
  cp "${VIMRC_SOURCE}" "${HOME}/.vimrc"

  # --- Neovim ---
  echo "Configuring Neovim (~/.config/nvim/init.vim)..."
  NVIM_CONFIG_DIR="${HOME}/.config/nvim"
  mkdir -p "${NVIM_CONFIG_DIR}"
  if [[ -f "${NVIM_CONFIG_DIR}/init.vim" ]]; then
    cp "${NVIM_CONFIG_DIR}/init.vim" "${NVIM_CONFIG_DIR}/init.vim.backup.$(date +%Y%m%d_%H%M%S)"
  fi
  cp "${VIMRC_SOURCE}" "${NVIM_CONFIG_DIR}/init.vim"

  # --- vim-plug (plugin manager) for Vim ---
  VIM_PLUG_FILE="${HOME}/.vim/autoload/plug.vim"
  if [[ ! -f "${VIM_PLUG_FILE}" ]]; then
    echo "Installing vim-plug for Vim..."
    curl -fLo "${VIM_PLUG_FILE}" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    echo "[OK] vim-plug for Vim already installed"
  fi

  # --- vim-plug (plugin manager) for Neovim ---
  NVIM_DATA_DIR="$(nvim --headless -c 'echo stdpath("data")' -c 'quit' 2>&1 | tail -1)"
  NVIM_PLUG_FILE="${NVIM_DATA_DIR}/site/autoload/plug.vim"
  if [[ ! -f "${NVIM_PLUG_FILE}" ]]; then
    echo "Installing vim-plug for Neovim..."
    curl -fLo "${NVIM_PLUG_FILE}" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    echo "[OK] vim-plug for Neovim already installed"
  fi

  # --- Install plugins headlessly ---
  echo "Installing Vim plugins (this may take a minute)..."
  vim +PlugInstall +qall &>/dev/null || echo "Warning: Vim plugin install reported an issue. Run ':PlugInstall' manually in Vim."

  echo "Installing Neovim plugins (this may take a minute)..."
  nvim --headless +PlugInstall +qall &>/dev/null || echo "Warning: Neovim plugin install reported an issue. Run ':PlugInstall' manually in Neovim."

  echo "[OK] Vim/Neovim configuration installed"
else
  echo "Warning: vim/vimrc not found in repo root. Skipping Vim/Neovim configuration."
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

# Install LiteLLM in an isolated virtual environment
echo "Setting up LiteLLM proxy..."
LITELLM_VENV="${HOME}/.venvs/litellm"
python3 -m venv "${LITELLM_VENV}"
"${LITELLM_VENV}/bin/python" -m pip install --upgrade pip 'litellm[proxy]'
echo "[OK] LiteLLM proxy installed in ${LITELLM_VENV}"

# --- LiteLLM proxy configuration (~/litellm_config.yaml) ---
LITELLM_CONFIG_FILE="${HOME}/litellm_config.yaml"
LITELLM_CONFIG_SOURCE="${SCRIPT_DIR}/litellm/litellm.config.yaml"
LITELLM_METADATA_DIR="${HOME}/.config/litellm"
LITELLM_EXPIRY_FILE="${LITELLM_METADATA_DIR}/api-key-expiry"
LITELLM_KEYCHAIN_SERVICE="mac_setup.litellm"

if [[ -f "${LITELLM_CONFIG_SOURCE}" ]]; then
  if [[ ! -f "${LITELLM_CONFIG_FILE}" ]]; then
    echo "Copying LiteLLM configuration template to ${LITELLM_CONFIG_FILE}..."
    cp "${LITELLM_CONFIG_SOURCE}" "${LITELLM_CONFIG_FILE}"
    echo "[OK] LiteLLM configuration installed"
  else
    echo "[OK] ${LITELLM_CONFIG_FILE} already exists."
  fi

  read -r -p "LiteLLM の api_key を更新しますか？ (y/n): " UPDATE_LITELLM_KEY
  if [[ "${UPDATE_LITELLM_KEY}" =~ ^[Yy]$ ]]; then
    while true; do
      read -r -s -p "新しい Anthropic API key: " LITELLM_API_KEY
      echo ""
      if [[ -n "${LITELLM_API_KEY}" && "${LITELLM_API_KEY}" != *$'\n'* ]]; then
        break
      fi
      echo "API key が空です。もう一度入力してください。"
    done

    while true; do
      read -r -p "API key の有効期限 (YYYY-MM-DD): " LITELLM_EXPIRY_DATE
      if [[ "${LITELLM_EXPIRY_DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && \
        date -j -f "%Y-%m-%d" "${LITELLM_EXPIRY_DATE}" "+%Y-%m-%d" >/dev/null 2>&1; then
        break
      fi
      echo "日付の形式または値が不正です。YYYY-MM-DD で入力してください。"
    done

    cp "${LITELLM_CONFIG_FILE}" "${LITELLM_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    API_KEY="${LITELLM_API_KEY}" awk '
      /api_key:/ {
        print substr($0, 1, index($0, "api_key:") - 1) "api_key: \"" ENVIRON["API_KEY"] "\""
        next
      }
      { print }
    ' "${LITELLM_CONFIG_FILE}" > "${LITELLM_CONFIG_FILE}.tmp"
    mv "${LITELLM_CONFIG_FILE}.tmp" "${LITELLM_CONFIG_FILE}"

    mkdir -p "${LITELLM_METADATA_DIR}"
    chmod 700 "${LITELLM_METADATA_DIR}"
    printf '%s\n' "${LITELLM_EXPIRY_DATE}" > "${LITELLM_EXPIRY_FILE}"
    chmod 600 "${LITELLM_EXPIRY_FILE}"
    security add-generic-password -U -s "${LITELLM_KEYCHAIN_SERVICE}" -a "${USER}" -w "${LITELLM_API_KEY}" >/dev/null
    unset LITELLM_API_KEY
    echo "[OK] API key を設定し、有効期限を ${LITELLM_EXPIRY_FILE} に保存しました。"
  else
    echo "API key は変更しません。"
  fi
else
  echo "Warning: litellm/litellm.config.yaml not found in repo root. Skipping LiteLLM configuration."
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
- Neovim + Vim with a shared config (~/.vimrc, ~/.config/nvim/init.vim)
  * vim-plug plugin manager (auto-installed for both Vim & Neovim)
  * gruvbox theme + vim-airline status line
  * NERDTree, fzf.vim, ripgrep integration
  * vim-fugitive, vim-gitgutter (Git integration)
  * vim-surround, vim-commentary, auto-pairs, indentLine
  * coc.nvim (autocompletion / LSP, uses your installed Node.js)
- Continue extension configuration (~/.continue/config.yaml)
- LiteLLM proxy configuration (~/litellm_config.yaml)

=== Next Steps ===
1. Reload your shell:
   source ~/.zshrc

2. (Optional) Install Starship config:
   mkdir -p ~/.config/starship
   touch ~/.config/starship.toml

3. Check installed tools:
   brew list
  ollama --version
   kubectl version --client
   colima status
  copilot --version
  code --list-extensions

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

LiteLLM:
  lllm                 # Start the LiteLLM proxy in the background (port 8000)
  edit ~/litellm_config.yaml  # Add/update models & API keys

VS Code:
  code --list-extensions  # List installed extensions
  Continue                # Continue extension with Ollama

Vim / Neovim:
  vim                  # Launch Vim with the new config
  nvim                 # Launch Neovim with the same config
  :PlugInstall         # (Re)install plugins manually if needed
  :PlugUpdate          # Update plugins
  <Space>e             # Toggle NERDTree file explorer
  <Space>f             # Fuzzy find files (fzf)
  <Space>g             # Fuzzy search text in project (ripgrep)

=== Notes ===
- Your old .zshrc was backed up (if it existed)
- Your old .vimrc / nvim init.vim were backed up (if they existed)
- Your old ~/.continue/config.yaml was backed up (if it existed)
- LiteLLM API key は install.sh の確認後に更新でき、更新前の設定はバックアップされます
- LiteLLM API key の有効期限は `~/.config/litellm/api-key-expiry` に保存され、期限切れ時に警告されます
- Colima will auto-start on macOS boot
- Colima logs: tail -f /var/log/colima.log
- LaunchAgent status: launchctl list | grep colima
- VS Code settings and extensions are managed in .vscode/

Enjoy your development setup!

NOTE
