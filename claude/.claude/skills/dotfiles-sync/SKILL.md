---
name: dotfiles-sync
description: Sync the ~/dotfiles repo (Claude Code settings, hooks, skills, zsh/vim/tmux/ssh config) from this machine to all lab servers. Use when the user asks to sync dotfiles, propagate settings/config changes to servers, or after editing anything under ~/dotfiles that other machines should pick up.
---

# Dotfiles Sync

Push local ~/dotfiles to origin, then pull on every server that has a clone.
GitHub is the hub; servers never sync peer-to-peer.

## Hosts

| Host | User | Has dotfiles | Runs Claude Code | Notes |
|------|------|--------------|------------------|-------|
| ai2 (gsai-login-2) | dongwookim | yes | yes | Slurm login node. The sync target that matters most. |
| stail / bypass (seoul) | dongwoo | yes | no | Jump host for a-i and ai2. |
| i (istanbul) | dongwoo | yes | no | Lab GPU node. |
| a-h | dongwoo | no | no | No clone; skip unless the user asks to bootstrap one. |
| s, ai, ai3, mllab | - | unknown | unknown | Often unreachable without VPN; report timeout, don't retry. |

Homes are NOT shared between machines. Each host needs its own pull.

## Procedure

1. Local: commit and push.
   - `cd ~/dotfiles && git status --short`
   - If dirty, show the diff, commit with a descriptive message, `git push origin main`.
   - If the push is rejected, `git pull --rebase origin main` first, then push.

2. Each remote host:
   ```bash
   ssh -o BatchMode=yes -o ConnectTimeout=12 <host> '~/dotfiles/bin/sync'
   ```
   bin/sync pulls --ff-only, relinks everything (including new skills), and
   verifies the links. It aborts if the tree is dirty; see Rules.

3. Verify the synced value landed, e.g.
   `ssh <host> 'grep remoteControlAtStartup ~/.claude/settings.json'`.

4. Report a table: host, synced or skipped, why.

## Rules

- `--ff-only` always. Never force-push, never `git reset`, never stash or discard
  remote local changes without showing the diff and getting explicit approval.
- If a host has local uncommitted changes that block the pull, show the diff.
  Machine-specific values belong in the untracked counterparts
  (`~/.zshrc.local`, `~/.ssh/config.local`, `~/.claude/settings.local.json`):
  migrate them there, stash the tracked edit, then sync.
- Unreachable host (timeout): report and move on. Do not retry in a loop.
- New files under gitignored paths (e.g. `claude/.claude/hooks/*`) need
  `git add -f` locally before they will sync at all.
