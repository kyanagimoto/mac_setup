# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A dotfiles / provisioning repository for a macOS development machine. There is no application code, no build, no test suite, and no linter — the "product" is `install.sh` plus the config files it deploys into `$HOME`. Validation is manual: run the installer and check that the tools respond.

## Commands

```bash
./install.sh                       # full provisioning run (idempotent, safe to re-run)
source ~/.zshrc                    # apply shell changes after editing .zshrc

# targeted re-runs when iterating on one piece
brew bundle --file=Brewfile        # just the package manifest
bash -n install.sh                 # syntax-check the installer without executing it

# verification after a run
brew list && colima status && kubectl version --client
code --list-extensions
tail -f /var/log/colima.log        # Colima auto-start diagnostics
launchctl list | grep colima
```

There is no way to run "one test". To exercise a single section of `install.sh`, copy that block into a scratch shell rather than adding flags to the script.

## Architecture

`install.sh` is the only executable and the single orchestrator. Every other tracked file is a *source* that the installer copies to a fixed destination in `$HOME`; the repo is the source of truth, the home directory is the deployed copy. Editing `~/.zshrc` directly is a mistake — the next `./install.sh` overwrites it.

| Repo source | Deployed to |
| --- | --- |
| `Brewfile` | consumed in place by `brew bundle` |
| `.zshrc` | `~/.zshrc` |
| `vim/vimrc` | both `~/.vimrc` *and* `~/.config/nvim/init.vim` |
| `continue/continue.config.yaml` | `~/.continue/config.yaml` |
| `.vscode/extensions.json`, `.vscode/settings.json` | used as workspace settings; extensions installed via `code --install-extension` |
| `colima.yaml` | `~/.colima/_templates/default.yaml` (Colima's new-instance template) |
| *(generated inline by install.sh)* | `~/Library/LaunchAgents/com.mac-setup.colima.plist` |

The installer's phases run in a fixed order and each is independently skippable: Homebrew bootstrap → `brew bundle` → Colima config + LaunchAgent → zsh → VS Code extensions → Continue config → Vim/Neovim (incl. vim-plug bootstrap and headless `:PlugInstall`) → optional tools (nvm) → summary heredoc.

### Invariants to preserve when editing `install.sh`

- **Idempotent.** Guard every step with `command -v` / `[[ -f ]]` / `brew list` checks so a second run is a no-op.
- **Timestamped backups before any overwrite.** `.zshrc`, `.vimrc`, `init.vim`, and `~/.continue/config.yaml` are each copied to `<file>.backup.$(date +%Y%m%d_%H%M%S)` first. New deployed files must do the same.
- **Missing source ⇒ warn and continue, never fail.** The script runs under `set -euo pipefail`, so optional steps use `|| true` or an explicit `if [[ -f ... ]] … else echo "Warning: …"`. Every deployed file's block is written so a deleted source degrades to a warning, not an abort.
- **Apple Silicon and Intel both.** Anything touching Homebrew paths must try `/opt/homebrew` then `/usr/local` — this appears in the installer's brew bootstrap, `.zshrc`, the LaunchAgent's `ProgramArguments`, and `vim/vimrc`'s fzf runtimepath.
- **ASCII only in terminal output.** Earlier commits deliberately replaced emoji with `[OK]` / `[COMPLETE]` markers because of terminal font rendering; keep script output ASCII (README prose may use emoji).
- **The trailing summary heredoc is part of the contract.** If you add or remove a provisioning step, update the "What was installed" / "Useful Commands" sections at the end of the script too.

### Documentation is a deliverable here

Three documents describe the same system and drift easily. A change to `install.sh`, `Brewfile`, or any config must be reflected in all that cover it:

- `README.md` — user-facing, **written in Japanese**; the authoritative description of features, aliases, keymaps, and troubleshooting.
- `.github/copilot-instructions.md` — English architecture notes for Copilot, overlapping heavily with this file.
- the summary heredoc at the end of `install.sh`.

Language convention: `README.md` and `vim/vimrc` comments are Japanese; `install.sh` and `.zshrc` comments are English. Match the file you are editing.

## Deliberate decisions and gotchas

- **No starship.** It was removed in commit `0f98835` over terminal rendering issues. The prompt is the hand-written `PS1` at `.zshrc:182`, built from the `git_branch` and `kubernetes_context` functions above it. Don't reintroduce starship without a reason.
- **`colima.yaml` is a template, not live config.** Colima reads new-instance defaults from `~/.colima/_templates/default.yaml`; the live instance keeps its own copy at `~/.colima/<profile>/colima.yaml`. Re-running `./install.sh` therefore does **not** reconfigure an existing VM — that needs `colima delete && colima start` (destroys VM data) or `colima start --edit`. Resolve the path with `colima template --print` rather than hardcoding it; it has moved between Colima versions.
- **Host-specific Colima fields are omitted on purpose.** `arch`, `vmType`, `cpuType`, and `mountType` are left out of `colima.yaml` so Colima picks `vz`/`virtiofs` on Apple Silicon and `qemu` on Intel. Pinning them breaks one architecture or the other.
- **Ollama is not installed by `install.sh`.** `README.md` documents it as a manual `brew install ollama`, and the Continue↔Ollama connection is entered by hand in the Continue UI. The model ID `gemma4:12b` must stay in sync across `README.md`, `continue/continue.config.yaml`, and the `ollama-gemma` alias in `.zshrc`.
