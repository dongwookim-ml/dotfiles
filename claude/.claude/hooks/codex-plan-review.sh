#!/bin/bash
# PreToolUse hook for ExitPlanMode.
# Sends Claude's proposed plan to Codex for review.
#   APPROVE -> let ExitPlanMode through (plan shown to user)
#   REVISE  -> deny the tool call, feed Codex's notes back so Claude revises
# Fail-open: any Codex error lets the plan through (never trap the user in plan mode).

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/local/bin:$PATH"
MAX_ROUNDS=3

payload="$(cat)"
plan="$(printf '%s' "$payload" | jq -r '.tool_input.plan // empty' 2>/dev/null)"
session="$(printf '%s' "$payload" | jq -r '.session_id // "nosession"' 2>/dev/null)"

# Nothing to review -> allow.
[ -z "$plan" ] && exit 0

# Per-session revision counter to bound the review loop.
state_dir="$HOME/.claude/hooks/state"
mkdir -p "$state_dir"
counter="$state_dir/plan-review-${session}.count"
n=0
[ -f "$counter" ] && n="$(cat "$counter" 2>/dev/null || echo 0)"
case "$n" in ''|*[!0-9]*) n=0 ;; esac
if [ "$n" -ge "$MAX_ROUNDS" ]; then
  rm -f "$counter"          # give up reviewing, accept the plan
  exit 0
fi

prompt="You are a senior engineer reviewing an implementation PLAN written by another AI agent.
Do not write or run code. Judge only the plan: correctness, missing steps, risky or irreversible
actions, wrong assumptions, and clearly simpler alternatives.

Output rules (strict):
- First line MUST be exactly \"VERDICT: APPROVE\" or \"VERDICT: REVISE\".
- APPROVE unless there are material problems. Do NOT request stylistic, trivial, or speculative changes.
- If REVISE, follow with a short bullet list of concrete, required changes. No praise, no filler.

PLAN:
$plan"

review="$(printf '%s' "$prompt" | codex exec --skip-git-repo-check -s read-only --color never - 2>/dev/null)"

# Codex failed or returned nothing -> fail open.
[ -z "$review" ] && exit 0

verdict="$(printf '%s\n' "$review" | grep -m1 -i '^VERDICT:')"

if printf '%s' "$verdict" | grep -qi 'APPROVE'; then
  rm -f "$counter"
  exit 0
fi

# REVISE (or no clear verdict) -> block and return Codex's notes to Claude.
echo $((n + 1)) > "$counter"
feedback="$(printf '%s\n' "$review" | awk 'toupper($0) !~ /^VERDICT:/')"
reason="Codex reviewed your plan and requires revisions before it is shown to the user (round $((n + 1)) of ${MAX_ROUNDS}). Revise the plan to address the following, then call ExitPlanMode again:

${feedback}"

jq -cn --arg r "$reason" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
