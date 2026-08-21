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
# Git Branch Display
# ============================================================================

# Function to get current git branch
git_branch() {
  if command -v git &> /dev/null; then
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
      echo " [$branch]"
    fi
  fi
}

# ============================================================================
# Custom Prompt with Colors & Git Branch
# ============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Custom prompt: user@host:path [git-branch] $
# Uses colors and git branch for better development experience
setopt PROMPT_SUBST
PS1="%F{cyan}%n%f:%F{blue}%~%f\$(git_branch)%F{yellow}%f "

# ============================================================================
# Welcome & Motivation Message
# ============================================================================

# Show a quick status and motivational message
echo "---"
echo "Welcome to your development shell!"
echo "Loaded tools: git, docker, kubectl, node, python"
echo "---"
