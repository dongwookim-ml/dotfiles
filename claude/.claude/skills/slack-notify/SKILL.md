---
name: slack-notify
description: Send Slack DM notifications when code execution completes. Use this skill at the end of any code execution task to notify the user via Slack webhook with job name, completion status, and result summary.
---

# Slack Notification Skill

Send a Slack DM notification when a job/code execution completes.

## Prerequisites

The user must provide a Slack webhook URL. To create one:
1. Go to https://api.slack.com/apps → Create New App → From scratch
2. Add "Incoming Webhooks" feature and activate it
3. Click "Add New Webhook to Workspace" and select the DM channel (Slackbot or direct message)
4. Copy the webhook URL

Set the webhook URL via environment variable:
```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

## Usage

Run the script after code execution completes:

```bash
python3 scripts/send_notification.py \
  --job-name "Data Processing" \
  --status "success" \
  --summary "Processed 1,234 records in 45 seconds"
```

## Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--webhook-url` | Slack incoming webhook URL (optional, uses SLACK_WEBHOOK_URL env var) | `https://hooks.slack.com/services/...` |
| `--job-name` | Brief name of the job | `"CSV Export"`, `"Report Generation"` |
| `--status` | Completion status | `"success"`, `"failure"`, `"completed"` |
| `--summary` | Result summary (keep concise) | `"Generated 5 charts, exported to PDF"` |

## Status Formatting

- `success`, `completed`, `done`, `passed` → green
- `failure`, `failed`, `error` → red
- Other values → blue

## Workflow

1. Execute the user's code/task
2. After completion, call `send_notification.py` with results
3. Confirm notification was sent

Note: Set SLACK_WEBHOOK_URL in ~/.zshrc.local. Override per-call with `--webhook-url`.
