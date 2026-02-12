# Dotfiles

Personal development environment managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone git@github.com:dongwookim-ml/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Structure

```
dotfiles/
├── zsh/          → ~/.zshrc
├── vim/          → ~/.vimrc
├── tmux/         → ~/.tmux.conf
├── ssh/          → ~/.ssh/config
├── claude/       → ~/.claude/{settings.json, skills/}
├── scripts/      → Utility scripts (not stowed)
└── install.sh    → Bootstrap script
```

Each top-level directory is a "stow package". Running `stow -t ~ zsh` symlinks
everything inside `zsh/` into your home directory.

## Machine-Specific Config

Create `~/.zshrc.local` for settings that vary per machine:

```bash
# conda init block
# export GITHUB_TOKEN="..."
# export SLACK_WEBHOOK_URL="..."
# Custom PATH additions
```

This file is sourced at the end of `.zshrc` and is not tracked by git.

## What's Included

### Zsh
- Powerlevel10k theme
- Plugins: git, z, fzf, zsh-autosuggestions, zsh-syntax-highlighting
- Better history, useful aliases

### Tmux
- `C-a` prefix, mouse support
- `|` / `-` splits, vim-style pane navigation
- Styled status bar, true color, TPM

### Vim
- vim-plug with: NERDTree, fugitive, surround, fzf.vim, airline, gitgutter, commentary, vimtex
- Relative line numbers, persistent undo, smart search
- `C-p` files, `<leader>b` buffers, `<leader>rg` ripgrep

### Claude Code
- Settings, enabled plugins, status line config
- Slack notification skill

### SSH
- Host config only (no private keys)
