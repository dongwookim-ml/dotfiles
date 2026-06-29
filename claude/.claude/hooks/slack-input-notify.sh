#!/bin/bash
# Notification hook: Slack-DM me whenever Claude is waiting on my input.
# Fires on permission prompts and idle-input notifications.
# stdin payload: .message (the reason), .transcript_path (for the actual question), .cwd.
PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

payload="$(cat)"
msg="$(printf '%s' "$payload" | jq -r '.message // empty')"
tpath="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"

# Skip the generic idle "waiting for your input" notification that fires after a
# turn finishes: job completion is already covered by the Stop hook
# (slack-job-notify.sh). Only ping for actionable requests like permission prompts.
case "$(printf '%s' "$msg" | tr '[:upper:]' '[:lower:]')" in
  *"waiting for your input"*) exit 0 ;;
esac

# What Claude is actually asking = last assistant text in the transcript.
ctx=""
if [ -n "$tpath" ] && [ -f "$tpath" ]; then
  ctx="$(jq -rc 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' "$tpath" 2>/dev/null | tail -1)"
  ctx="$(printf '%s' "$ctx" | tr '\n' ' ' | cut -c1-700)"
fi

# Meaningful summary: the notification reason plus Claude's last message.
if [ -n "$msg" ] && [ -n "$ctx" ]; then
  summary="$(printf '%s\n%s' "$msg" "$ctx")"
elif [ -n "$ctx" ]; then
  summary="$ctx"
else
  summary="$msg"
fi
[ -z "$summary" ] && exit 0

job="Claude Code"
[ -n "$cwd" ] && job="$(basename "$cwd")"

python3 "$HOME/.claude/skills/slack-notify/scripts/send_notification.py" \
  --job-name "$job" --status "input needed" --summary "$summary" >/dev/null 2>&1 || true
exit 0
