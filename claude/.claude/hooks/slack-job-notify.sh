#!/bin/bash
# Stop hook: Slack-notify long jobs WITH a real title + summary.
# Elapsed time comes from the /tmp marker written by the UserPromptSubmit hook.
# Title  = the human prompt that started the turn (the task).
# Summary = the final assistant text message in the session transcript.
# Uses python3 (portable across macOS + Linux); no jq dependency.
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

payload="$(cat)"

# Parse session_id, transcript_path, cwd from the hook payload (one field per line).
fields="$(printf '%s' "$payload" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
print(d.get("session_id", "default"))
print(d.get("transcript_path", ""))
print(d.get("cwd", ""))
')"
sid="$(printf '%s\n' "$fields" | sed -n 1p)"
tpath="$(printf '%s\n' "$fields" | sed -n 2p)"
cwd="$(printf '%s\n' "$fields" | sed -n 3p)"
[ -n "$sid" ] || sid="default"

f="/tmp/claude-turn-start-$sid"
[ -f "$f" ] || exit 0
start="$(cat "$f")"; rm -f "$f"
el=$(( $(date +%s) - start ))
thr="${CLAUDE_LONG_JOB_SECONDS:-600}"
[ "$el" -ge "$thr" ] || exit 0
m=$((el / 60)); s=$((el % 60))

# One transcript pass -> line 1: task (title), line 2: summary. Each pre-sanitized
# to a single line so the bash side can split on lines safely.
title=""; summary=""
if [ -n "$tpath" ] && [ -f "$tpath" ]; then
  out="$(python3 - "$tpath" <<'PY'
import sys, json
path = sys.argv[1]
task = ""      # last human prompt (the task)
last = ""      # last non-empty assistant text block
try:
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except Exception:
                continue
            t = o.get("type")
            content = (o.get("message") or {}).get("content")
            if t == "user":
                # Human prompts arrive as a plain string; skip injected
                # tool results (lists) and local-command/caveat wrappers ("<...>").
                if isinstance(content, str):
                    c = content.strip()
                    if c and not c.startswith("<"):
                        task = c
            elif t == "assistant" and isinstance(content, list):
                for blk in content:
                    if isinstance(blk, dict) and blk.get("type") == "text" and blk.get("text", "").strip():
                        last = blk["text"]
except Exception:
    pass

def clean(s, n):
    s = " ".join(s.split())          # collapse all whitespace incl newlines
    return s[:n] + ("..." if len(s) > n else "")

print(clean(task, 80))
print(clean(last, 700))
PY
)"
  title="$(printf '%s\n' "$out" | sed -n 1p)"
  summary="$(printf '%s\n' "$out" | sed -n 2p)"
fi

[ -z "$summary" ] && summary="(no transcript summary found)"
summary="Took ${m}m ${s}s. ${summary}"

job="$title"
[ -z "$job" ] && [ -n "$cwd" ] && job="$(basename "$cwd")"
[ -z "$job" ] && job="Claude Code job"

python3 "$HOME/.claude/skills/slack-notify/scripts/send_notification.py" \
  --job-name "$job" --status completed --summary "$summary" >/dev/null 2>&1 || true
exit 0
