# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package that symlinks its contents into `$HOME`.

## Common Commands

```bash
# Bootstrap a new machine (installs brew, stow, oh-my-zsh, plugins, then stows all packages)
./install.sh

# Stow a single package (symlinks into ~)
stow -t ~ zsh

# Re-stow all packages (useful after adding/removing files)
stow -t ~ --restow zsh vim tmux ssh claude

# Remove symlinks for a package
stow -t ~ -D vim

# Install vim plugins after editing .vimrc
vim +PlugInstall +qall

# Install tmux plugins (inside tmux)
# Prefix (Ctrl-a) + Shift-I
```

## Architecture

### GNU Stow Layout

Each directory mirrors the home directory structure. Stow creates symlinks:
- `zsh/.zshrc` → `~/.zshrc`
- `vim/.vimrc` → `~/.vimrc`
- `tmux/.tmux.conf` → `~/.tmux.conf`
- `ssh/.ssh/config` → `~/.ssh/config`
- `claude/.claude/` → `~/.claude/`

### Packages

| Package | Key details |
|---------|-------------|
| **zsh** | Powerlevel10k, Oh My Zsh, sources `~/.zshrc.local` at end for machine-specific config |
| **vim** | vim-plug (auto-bootstraps), Solarized theme, heavy fzf/git integration, Python & LaTeX support |
| **tmux** | Prefix remapped to `C-a`, TPM for plugins, vim-style navigation |
| **ssh** | Host aliases only — private keys excluded via .gitignore |
| **claude** | Claude Code settings.json and custom slack-notify skill |

### Machine-Specific Secrets

Credentials and machine-local config go in `~/.zshrc.local` (git-ignored, sourced by `.zshrc`). Never commit tokens, keys, or webhook URLs to this repo.

## Conventions

- When adding a new tool's config, create a new stow package directory mirroring the home directory path (e.g., `git/.gitconfig` for `~/.gitconfig`).
- Plugin managers handle their own installation: vim-plug auto-curls on first vim launch; TPM clones on `install.sh` run.
- The `install.sh` script is idempotent — safe to re-run. If existing (non-symlink) files conflict with a stow package, it prompts to overwrite and backs up originals as `.bak`.
- **Linux support**: On Linux, the script runs without sudo. It installs fzf locally to `~/.fzf` if not found, and falls back to manual symlinks (`ln -sf`) when stow is unavailable. Only `tmux` and `zsh` are hard requirements.
