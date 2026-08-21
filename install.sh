#!/usr/bin/env bash
set -euo pipefail

echo "=== mac_setup: Homebrew + Brewfile installer ==="

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

cat <<'NOTE'

Done.

Notes:
- For mac App Store apps via 'mas' you must login to the App Store and include mas entries (app IDs) in the Brewfile.
- This script attempts to make Homebrew available in the current shell, but you may need to add the 'brew shellenv' line to your shell profile (e.g. ~/.zprofile or ~/.bash_profile) for future shells.

Example usage:
  chmod +x install.sh
  ./install.sh

NOTE
