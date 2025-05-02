# Setting up Microsoft Teams Notifications for the Draw.io Workflow

This guide explains how to set up Microsoft Teams notifications for the Draw.io conversion workflow.

## Overview

The workflow is configured to send notifications to a Microsoft Teams channel when:
- The workflow completes successfully (green notification)
- The workflow fails (red notification with error details)

## Prerequisites

1. Microsoft Teams admin access or permission to create connectors
2. GitHub repository admin access to add secrets

## Setup Steps

### 1. Create a Teams Webhook

1. Open Microsoft Teams
2. Navigate to the channel where you want to receive notifications
3. Click the "..." menu next to the channel name
4. Select "Connectors"
5. Find "Incoming Webhook" and click "Configure"
6. Give your webhook a name (e.g., "Draw.io Conversion Alerts")
7. Optionally upload an icon for the webhook
8. Click "Create"
9. Copy the webhook URL that's generated - you'll need this for the next step

### 2. Add the Webhook URL as a GitHub Secret

1. Go to your GitHub repository
2. Click on "Settings"
3. In the left sidebar, click on "Secrets and variables" > "Actions"
4. Click "New repository secret"
5. Name: `TEAMS_WEBHOOK`
6. Value: Paste the webhook URL you copied from Teams
7. Click "Add secret"

## Notification Format

### Success Notification
- Color: Green
- Title: "✅ Draw.io Conversion Workflow Completed"
- Details: Repository, workflow name, commit, and triggering user
- Action button: Link to the workflow run

### Failure Notification
- Color: Red
- Title: "❌ Draw.io Conversion Workflow Failed"
- Details: Repository, workflow, commit, triggering user, and run ID
- Action button: Link to the workflow run

## Customizing Notifications

To customize the notification format, edit the workflow file at `.github/workflows/drawio-convert.yml` in the `teams-notification` job section.

## Troubleshooting

If notifications aren't being sent:

1. Verify the webhook URL is correct in the GitHub secrets
2. Check if the workflow is completing or failing as expected
3. Review the "teams-notification" job logs in the GitHub Actions run
4. Ensure the Teams channel and connector are properly configured

## Security Note

The webhook URL provides direct access to post messages to your Teams channel. Keep it secure and never commit it directly in code.
