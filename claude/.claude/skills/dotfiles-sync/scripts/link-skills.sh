#!/bin/bash
# Symlink every skill in ~/dotfiles/claude/.claude/skills into ~/.claude/skills.
# Idempotent: existing correct links are left alone, missing ones are created.
src="$HOME/dotfiles/claude/.claude/skills"
dst="$HOME/.claude/skills"
mkdir -p "$dst"
for d in "$src"/*/; do
  name="$(basename "$d")"
  [ -e "$dst/$name" ] || { ln -s "${d%/}" "$dst/$name" && echo "linked $name"; }
done
