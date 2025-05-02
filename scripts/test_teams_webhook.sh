#!/bin/zsh
# Teams Webhook Test Script
# Usage: ./test_teams_webhook.sh YOUR_WEBHOOK_URL

if [ -z "$1" ]; then
  echo "Error: Missing webhook URL"
  echo "Usage: ./test_teams_webhook.sh YOUR_WEBHOOK_URL"
  exit 1
fi

WEBHOOK_URL="$1"
GITHUB_USER="lucasdreger"  # Change to your GitHub username

# Create JSON payload that includes profile picture
cat > teams_test_payload.json << EOF
{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "0076D7",
  "summary": "Teams Webhook Test",
  "sections": [
    {
      "activityTitle": "🧪 Teams Webhook Test with Profile Picture",
      "activitySubtitle": "$(date +'%d.%m.%Y %H:%M:%S')",
      "activityImage": "https://github.com/$GITHUB_USER.png?size=40",
      "facts": [
        {
          "name": "Purpose",
          "value": "Testing profile image and direct links"
        },
        {
          "name": "Sent by",
          "value": "$GITHUB_USER"
        },
        {
          "name": "Date",
          "value": "$(date +'%d.%m.%Y %H:%M:%S')"
        },
        {
          "name": "Repo",
          "value": "lucasdreger/diagrams"
        }
      ],
      "text": "This message should show the GitHub profile picture of $GITHUB_USER and appear to be sent by this user instead of \"Unknown user\"."
    }
  ],
  "potentialAction": [
    {
      "@type": "OpenUri",
      "name": "View Repository",
      "targets": [
        {
          "os": "default",
          "uri": "https://github.com/lucasdreger/diagrams"
        }
      ]
    }
  ]
}
EOF

# Send the notification to Teams webhook
echo "Sending test message to Teams..."
curl -H "Content-Type: application/json" -d @teams_test_payload.json "$WEBHOOK_URL"
echo ""
echo "Message sent! Check your Teams channel."
