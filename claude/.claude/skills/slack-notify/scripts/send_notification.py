#!/usr/bin/env python3
"""Send a Slack notification via webhook URL."""

import argparse
import json
import os
import urllib.request
import urllib.error
import sys


def send_slack_notification(webhook_url: str, job_name: str, status: str, summary: str) -> bool:
    """
    Send a notification to Slack via webhook.

    Args:
        webhook_url: Slack incoming webhook URL
        job_name: Name/description of the completed job
        status: Completion status (e.g., "success", "failure", "completed")
        summary: Brief summary of results

    Returns:
        True if successful, False otherwise
    """
    # Choose emoji based on status
    status_lower = status.lower()
    if status_lower in ("success", "completed", "done", "passed"):
        emoji = "\u2705"
        color = "#36a64f"
    elif status_lower in ("failure", "failed", "error"):
        emoji = "\u274c"
        color = "#dc3545"
    else:
        emoji = "\u2139\ufe0f"
        color = "#0dcaf0"

    # Build message payload with attachment for rich formatting
    payload = {
        "attachments": [
            {
                "color": color,
                "blocks": [
                    {
                        "type": "header",
                        "text": {
                            "type": "plain_text",
                            "text": f"{emoji} Job Completed: {job_name}",
                            "emoji": True
                        }
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Status:*\n{status}"
                            }
                        ]
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"*Summary:*\n{summary}"
                        }
                    }
                ]
            }
        ]
    }

    # Send request
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=data,
        headers={"Content-Type": "application/json"}
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.status == 200
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code} - {e.reason}", file=sys.stderr)
        return False
    except urllib.error.URLError as e:
        print(f"URL Error: {e.reason}", file=sys.stderr)
        return False


def main():
    default_url = os.environ.get("SLACK_WEBHOOK_URL", "")

    parser = argparse.ArgumentParser(description="Send Slack notification via webhook")
    parser.add_argument("--webhook-url", default=default_url, help="Slack webhook URL (default: SLACK_WEBHOOK_URL env var)")
    parser.add_argument("--job-name", required=True, help="Name of the completed job")
    parser.add_argument("--status", required=True, help="Completion status (e.g., success, failure)")
    parser.add_argument("--summary", required=True, help="Brief summary of results")

    args = parser.parse_args()

    if not args.webhook_url:
        print("Error: No webhook URL provided. Set SLACK_WEBHOOK_URL or use --webhook-url.", file=sys.stderr)
        sys.exit(1)

    success = send_slack_notification(
        webhook_url=args.webhook_url,
        job_name=args.job_name,
        status=args.status,
        summary=args.summary
    )

    if success:
        print("\u2705 Notification sent successfully")
        sys.exit(0)
    else:
        print("\u274c Failed to send notification", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
