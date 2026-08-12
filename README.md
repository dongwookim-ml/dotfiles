# Dotfiles

Personal development environment, symlinked into `$HOME` by `install.sh`.

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
├── claude/       → ~/.claude/{settings.json, CLAUDE.md, hooks/, skills/}
├── codex/        → ~/.codex/{hooks.json, hooks/}
├── bin/sync      → Pull + relink; --all fans out to every host in bin/hosts
└── install.sh    → Bootstrap script
```

Each top-level directory mirrors `$HOME`. `install.sh` creates one symlink per
file, except each directory under `claude/.claude/skills/`, which is linked
whole so new files inside a skill need no relink. Anything already in the way is
moved to `~/.dotfiles-backup/` first.

Day to day, after changing something on another machine:

```bash
~/dotfiles/bin/sync
```

After committing something on the laptop, push it to every machine at once:

```bash
~/dotfiles/bin/sync --all
```

That pushes, syncs the laptop, then runs `bin/sync` on each host listed in
`bin/hosts`. Add a machine by adding its ssh alias to that file, once it has a
clone and has had `./install.sh` run.

Syncing is deliberately manual. A bad line in `.ssh/config` or `.zshrc` can cost
you every connection from a machine, and that should land while you are watching,
not from a timer.

That pulls, refreshes the links, and reports any that do not resolve. A full
`./install.sh` run is only needed when setting up a new machine.

## Machine-Specific Config

Nothing machine-specific belongs in a tracked file. Each tool has an untracked
escape hatch:

| Tracked | Machine-local (untracked) |
|---------|---------------------------|
| `zsh/.zshrc` | `~/.zshrc.local` (conda init, tokens, PATH, `SLACK_WEBHOOK_URL`) |
| `ssh/.ssh/config` | `~/.ssh/config.local` |
| `claude/.claude/settings.json` | `~/.claude/settings.local.json` (`model`, `statusLine`, `mcpServers`, per-machine permissions) |

`~/.claude/settings.local.json` takes precedence over the tracked settings, and
Claude Code writes your permission grants into it, so it stays machine-local on
its own. Keep `enabledPlugins` and `extraKnownMarketplaces` in the tracked file;
they are not read from the local one.

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

### Codex
- Opens the ai2 Slurm monitoring page in the built-in browser after job submission

### SSH
- Host config only (no private keys)
