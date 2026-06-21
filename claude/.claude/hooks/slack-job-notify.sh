#!/bin/bash
# Stop hook: Slack-notify long jobs WITH a real summary.
# Elapsed time comes from the /tmp marker written by the UserPromptSubmit hook.
# The summary is the last assistant text message in the session transcript.
PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

payload="$(cat)"
sid="$(printf '%s' "$payload" | jq -r '.session_id // "default"')"
tpath="$(printf '%s' "$payload" | jq -r '.transcript_path // empty')"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"

f="/tmp/claude-turn-start-$sid"
[ -f "$f" ] || exit 0
start="$(cat "$f")"; rm -f "$f"
el=$(( $(date +%s) - start ))
thr="${CLAUDE_LONG_JOB_SECONDS:-600}"
[ "$el" -ge "$thr" ] || exit 0
m=$((el / 60)); s=$((el % 60))

# Real summary = final assistant text in the transcript.
summary=""
if [ -n "$tpath" ] && [ -f "$tpath" ]; then
  summary="$(jq -rc 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' "$tpath" 2>/dev/null | tail -1)"
fi
[ -z "$summary" ] && summary="(no transcript summary found)"
summary="$(printf '%s' "$summary" | tr '\n' ' ' | cut -c1-700)"
summary="Took ${m}m ${s}s. ${summary}"

job="Claude Code job"
[ -n "$cwd" ] && job="$(basename "$cwd")"

python3 "$HOME/.claude/skills/slack-notify/scripts/send_notification.py" \
  --job-name "$job" --status completed --summary "$summary" >/dev/null 2>&1 || true
exit 0
