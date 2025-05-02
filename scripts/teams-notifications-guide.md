# Teams Notifications for Draw.io Diagrams Workflow

## Overview

The Draw.io diagrams conversion workflow includes automatic Microsoft Teams notifications that alert you when:

1. **Success Notification**: The conversion completes successfully and files are updated
2. **Failure Notification**: The workflow encounters an error during execution

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
✅ Draw.io Conversion Completed Successfully
---------------------------------------------
Repository: your-org/diagrams
Files Processed: 3
Triggered by: username
SharePoint Upload: Completed

[View Workflow Run]
```

### Failure:
```
⚠️ Draw.io Conversion Workflow Failed
------------------------------------
Repository: your-org/diagrams
Branch: main
Triggered by: username
Commit: Update diagram file

[View Workflow Run]
```

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
