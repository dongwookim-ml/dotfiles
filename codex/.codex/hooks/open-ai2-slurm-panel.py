#!/usr/bin/env python3
"""Tell Codex to open the ai2 monitor after a successful Slurm submission."""

import json
import re
import socket
import sys


MONITOR_URL = "http://localhost:60377/"
SBATCH = re.compile(r"(?<![\w.-])sbatch\b")
SBATCH_COMMAND = re.compile(r"(?:^|[;&|()\n])\s*(?:[\w./-]+/)?sbatch\b")
AI2_SSH = re.compile(r"\bssh\b.*\b(?:ai2|aigc|141\.223\.25\.23)\b", re.DOTALL)


def failed(response):
    if isinstance(response, dict):
        if response.get("isError") is True:
            return True
        if "exit_code" in response and response["exit_code"] not in (None, 0):
            return True
        return any(failed(value) for value in response.values())
    if isinstance(response, list):
        return any(failed(value) for value in response)
    return False


def submitted_on_ai2(payload):
    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input") or {}

    if tool_name == "mcp__slurm__submit_job":
        return True

    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""
    if not isinstance(command, str) or not SBATCH.search(command):
        return False

    if tool_name == "mcp__slurm__run_command":
        return SBATCH_COMMAND.search(command) is not None

    hostname = socket.gethostname().lower()
    if hostname.startswith("gsai-login-2"):
        return SBATCH_COMMAND.search(command) is not None
    return AI2_SSH.search(command) is not None


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return

    if failed(payload.get("tool_response")) or not submitted_on_ai2(payload):
        return

    instruction = (
        "An ai2 Slurm job was just submitted successfully. Invoke "
        "$ai2-slurm-monitor, then use @Browser to open "
        f"{MONITOR_URL} in the built-in side panel. If that page is already "
        "open, refresh it. This is a standing user instruction: do not ask for "
        "confirmation and do not open an external browser."
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": instruction,
            }
        },
        sys.stdout,
    )


if __name__ == "__main__":
    main()
