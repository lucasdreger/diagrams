# Teams Notifications f### Success Notification (Green)
- ✅ Visual confirmation that the workflow completed successfully
- Number of files processed with a sample of processed files
- Who triggered the workflow (with profile picture)
- Link to view the specific job logs
- Link to view the complete workflow runw.io Diagrams Workflow

## Overview

The Draw.io diagrams conversion workflow includes automatic Microsoft Teams notifications that alert you when:

1. **Success Notification**: The conversion completes successfully and files are updated
2. **Failure Notification**: The workflow encounters an error during execution

> **Note:** Microsoft Teams webhooks are simple to use - they only require the webhook URL itself. No username, password, or additional authentication is needed as all the authorization is embedded in the URL.

## Sender Identification

By default, webhook messages appear with a generic sender name (often showing as "Unknown user"). Our workflow addresses this by:

1. Including the GitHub user's profile picture using `activityImage: "https://github.com/${{ github.actor }}.png?size=40"`
2. Using the full name (not just username) of who triggered the workflow when available
3. Using proper branding and styling to identify the message source

## How It Works

The workflow uses your configured `TEAMS_WEBHOOK` secret to send adaptive cards to your Microsoft Teams channel. These notifications provide:

### Success Notification (Green)
- ✅ Visual confirmation that the workflow completed successfully
- Number of files processed
- Who triggered the workflow
- Confirmation of SharePoint upload
- Link to view the workflow run details

### Failure Notification (Red)
- ⚠️ Immediate alert when something goes wrong
- Which repository and branch had the issue
- Who triggered the workflow
- The commit message that caused the error
- Link to view the workflow run for troubleshooting

## Sample Notifications

### Success:
```
[Profile Picture] ✅ Draw.io Diagrams Updated
---------------------------------------------
Repository: lucasdreger/diagrams
Files Processed: 3 (diagram1, diagram2, diagram3)
Triggered by: Lucas Dreger
Commit: Update SAP Cloud diagram

📊 Diagram updates are available and have been successfully processed.

[View Job Logs] [View Workflow Run]
```

### New Diagram:
```
[Profile Picture] ✅ New Draw.io Diagram Created
---------------------------------------------
Repository: lucasdreger/diagrams
Files Processed: 1 (3.2.1. SAP Cloud Simplified)
Triggered by: Lucas Dreger
Commit: Added 3.2.1. SAP Cloud Simplified.drawio

📋 New empty diagram(s) have been created: 3.2.1. SAP Cloud Simplified

[View Job Logs] [View Workflow Run]
```

### Failure:
```
[Profile Picture] ❌ URGENT: Draw.io Conversion Workflow Failed
------------------------------------
Repository: lucasdreger/diagrams
Branch: main
Triggered by: Lucas Dreger
Commit: Update diagram file
Failed Files: drawio_files/3.2.1. SAP Cloud Simplified.drawio
Job: convert (12345678)

⚠️ ALERT: The diagram conversion workflow has failed. Check the logs for more details.

[View Job Logs] [View Workflow Run]
```

All notifications include:
1. The GitHub profile picture of the person who triggered the workflow
2. The full name (when available) instead of just the GitHub username
3. An attachment to the CHANGELOG.csv file for reference and tracking

## Troubleshooting

If notifications aren't being sent:

1. **Check the TEAMS_WEBHOOK secret**: Make sure it's properly configured in your GitHub repository secrets.
2. **Review the workflow run**: Look at the specific step that failed to send the notification.
3. **Webhook expiration**: Teams webhooks can expire. If notifications stop working, you may need to generate a new webhook URL.

## Customizing Notifications

You can customize the notifications by editing the workflow file at `.github/workflows/drawio-convert.yml`. Look for the sections with `Send Teams notification` steps to modify:

- The color of the notification card (`themeColor`)
- The facts displayed in the card
- The title or subtitle text
- Additional actions or buttons
