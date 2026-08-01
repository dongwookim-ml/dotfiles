# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles. Each top-level directory mirrors `$HOME`, and `install.sh` symlinks its contents into place. Machines in use: this laptop, `stail` (seoul jump host, Ubuntu 18.04), and `ai2` (Slurm login node, AlmaLinux).

## Common Commands

```bash
# Bootstrap a new machine (brew/fzf, oh-my-zsh, plugins, TPM, then links)
./install.sh

# Pull and relink on an existing machine (the everyday command)
bin/sync

# Push, then sync every host in bin/hosts (run from the laptop)
bin/sync --all

# Relink only, no pull, no bootstrap
./install.sh --link-only

# Install vim plugins after editing .vimrc
vim +PlugInstall +qall

# Install tmux plugins (inside tmux)
# Prefix (Ctrl-a) + Shift-I
```

## Architecture

### Linking

`install.sh` creates one symlink per file:
- `zsh/.zshrc` → `~/.zshrc`
- `vim/.vimrc` → `~/.vimrc`
- `tmux/.tmux.conf` → `~/.tmux.conf`
- `ssh/.ssh/config` → `~/.ssh/config`
- `claude/.claude/settings.json` → `~/.claude/settings.json`

The exception is `claude/.claude/skills/<name>`, linked as a whole directory so
files added inside a skill appear without relinking. `~/.claude/skills/` itself
is never linked, since unrelated skills live there too.

Do not reintroduce GNU Stow. It cannot be installed without root on the lab
servers, and stow links directories where the fallback linked files, which left
the same package laid out three different ways across machines.

Displaced files are moved to `~/.dotfiles-backup/`, never to a `.bak` beside the
original: a `.bak` inside `skills/` is loaded as a duplicate skill.

### Packages

| Package | Key details |
|---------|-------------|
| **zsh** | Powerlevel10k, Oh My Zsh, sources `~/.zshrc.local` at end for machine-specific config |
| **vim** | vim-plug (auto-bootstraps), Solarized theme, heavy fzf/git integration, Python & LaTeX support |
| **tmux** | Prefix remapped to `C-a`, TPM for plugins, vim-style navigation |
| **ssh** | Host aliases only — private keys excluded via .gitignore |
| **claude** | Shared settings.json, global CLAUDE.md, hooks, and custom skills |

### Machine-Specific Config

Nothing that varies per machine belongs in a tracked file. Each tool has an
untracked counterpart: `~/.zshrc.local`, `~/.ssh/config.local`, and
`~/.claude/settings.local.json`. Never commit tokens, keys, or webhook URLs.

For Claude Code, keep `model`, `statusLine`, and `mcpServers` in
`settings.local.json`; keep `enabledPlugins` and `extraKnownMarketplaces` in the
tracked `settings.json`, because those two are not read from the local file.
Anything in a tracked file must work on every machine, so use `$HOME` rather
than an absolute home path.

## Conventions

- When adding a new tool's config, create a new package directory mirroring the home directory path (e.g., `git/.gitconfig` for `~/.gitconfig`).
- Plugin managers handle their own installation: vim-plug auto-curls on first vim launch; TPM clones on `install.sh` run.
- `install.sh` is idempotent. Re-running relinks nothing that is already correct.
- Before `ssh/.ssh/config` is linked, `install.sh` parses it with the local `ssh`
  and aborts on failure. An option newer than the oldest client makes ssh discard
  the whole config, so guard new options with `IgnoreUnknown`.
- **Linux support**: the script runs without sudo. It installs fzf locally to `~/.fzf` if not found. Only `tmux` and `zsh` are hard requirements.
