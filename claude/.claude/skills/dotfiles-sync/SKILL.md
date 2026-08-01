---
name: dotfiles-sync
description: Sync the ~/dotfiles repo (Claude Code settings, hooks, skills, zsh/vim/tmux/ssh config) from this machine to all lab servers. Use when the user asks to sync dotfiles, propagate settings/config changes to servers, or after editing anything under ~/dotfiles that other machines should pick up.
---

# Dotfiles Sync

Push local ~/dotfiles to origin, then pull on every server that has a clone.
GitHub is the hub; servers never sync peer-to-peer.

## Hosts

The list lives in `bin/hosts`, one ssh alias per line. It is the single source
of truth; do not hard-code hosts here or in a command.

| Host | User | Runs Claude Code | Notes |
|------|------|------------------|-------|
| ai2 (gsai-login-2) | dongwookim | yes | Slurm login node. The sync target that matters most. |
| stail / bypass (seoul) | dongwoo | no | Jump host for a-i and ai2. |
| i (istanbul) | dongwoo | no | Lab GPU node. |
| a-h | dongwoo | no | No clone; skip unless the user asks to bootstrap one. |
| s, ai, ai3, mllab | - | unknown | Often unreachable without VPN; report timeout, don't retry. |

Homes are NOT shared between machines. Each host needs its own pull.

## Procedure

1. Commit locally. `cd ~/dotfiles && git status --short`; if dirty, show the
   diff and commit with a descriptive message. Do not push by hand, step 2 does it.

2. Run the fan-out from the laptop:
   ```bash
   ~/dotfiles/bin/sync --all
   ```
   It pushes any unpushed commits, syncs this machine, then runs `bin/sync` on
   every host in `bin/hosts`. Each host pulls `--ff-only`, relinks everything
   including new skills, and verifies its links. It refuses to start if the
   local tree is dirty, and exits non-zero naming any host that failed.

3. Verify the change actually landed on the host that matters, e.g.
   `ssh ai2 'grep remoteControlAtStartup ~/.claude/settings.json'`.

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
