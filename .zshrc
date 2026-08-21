#!/usr/bin/env bash
# macOS zsh configuration for development

# ============================================================================
# Homebrew Configuration
# ============================================================================

# Apple Silicon & Intel support
if [[ -d /opt/homebrew/bin ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)" || true
fi

# ============================================================================
# NVM (Node Version Manager) Configuration
# ============================================================================

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ============================================================================
# Kubernetes/kubectl Configuration
# ============================================================================

# kubectl shell completion
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
  compdef _kubectl kubectl
fi

# Colima aliases
alias colima-start='colima start'
alias colima-stop='colima stop'
alias colima-status='colima status'

# ============================================================================
# Useful Aliases
# ============================================================================

# Directory navigation
alias ll='ls -lah'
alias la='ls -lA'
alias l='ls -lh'
alias cd..='cd ..'
alias ...='cd ../..'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git branch'
alias gco='git checkout'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'

# Docker aliases
alias d='docker'
alias dc='docker compose'
alias di='docker images'
alias dps='docker ps'

# macOS specific
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'

# ============================================================================
# Starship Prompt Configuration
# ============================================================================

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# ============================================================================
# Additional Configurations
# ============================================================================

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY

# Enable completion
autoload -Uz compinit && compinit

# Vi-like keybindings (optional - comment out if you prefer emacs)
# bindkey -v

# ============================================================================
# Python Configuration (optional)
# ============================================================================

# pyenv configuration (if installed)
if command -v pyenv &> /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# ============================================================================
# Path Configuration
# ============================================================================

# Add custom bin directories to PATH
export PATH="$HOME/.local/bin:$PATH"

# ============================================================================
# Useful Functions
# ============================================================================

# Docker cleanup function
dockerclean() {
  echo "Cleaning up Docker containers, images, and volumes..."
  docker container prune -f
  docker image prune -f
  docker volume prune -f
  echo "Docker cleanup complete!"
}

# Kubernetes context switcher
kctx() {
  if [ -z "$1" ]; then
    kubectl config current-context
  else
    kubectl config use-context "$1"
  fi
}

# Get all pod logs from a deployment
kgetlogs() {
  if [ -z "$1" ]; then
    echo "Usage: kgetlogs <deployment-name> [namespace]"
    return 1
  fi
  local namespace=${2:-default}
  local pods=$(kubectl get pods -n "$namespace" -l app="$1" -o jsonpath='{.items[*].metadata.name}')
  for pod in $pods; do
    echo "=== Logs for $pod ==="
    kubectl logs -n "$namespace" "$pod"
  done
}

# ============================================================================
# Welcome Message
# ============================================================================

echo "[mac_setup] Welcome to macOS development environment!"
echo "Installed tools:"
echo "  [OK] Homebrew: $(brew --version | head -n1)"
echo "  [OK] Node.js: $(node --version 2>/dev/null || echo 'not installed')"
echo "  [OK] Python: $(python3 --version 2>/dev/null || echo 'not installed')"
echo "  [OK] Git: $(git --version)"
echo "  [OK] kubectl: $(kubectl version --client --short 2>/dev/null || echo 'not installed')"
echo "  [OK] Docker: $(docker --version 2>/dev/null || echo 'not installed')"
echo "  [OK] Colima: $(colima --version 2>/dev/null || echo 'not installed')"
echo ""
