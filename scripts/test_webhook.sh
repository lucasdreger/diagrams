#!/bin/zsh
# Quick test for Teams webhook with your artifact secret
# Usage: ./test_webhook.sh

echo "Testing Teams webhook..."

# Create a simple payload
PAYLOAD=$(cat << EOF
{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "0076D7",
  "summary": "Quick test message",
  "sections": [
    {
      "activityTitle": "🔍 Teams Webhook Test",
      "activitySubtitle": "$(date +'%d.%m.%Y %H:%M:%S')",
      "activityImage": "https://github.com/lucasdreger.png?size=40",
      "facts": [
        {
          "name": "Purpose",
          "value": "Testing exact webhook from GitHub secret"
        },
        {
          "name": "Sender",
          "value": "Local test script"
        }
      ],
      "markdown": true,
      "text": "This test confirms your TEAMS_WEBHOOK secret is correctly configured."
    }
  ]
}
EOF
)

# Read the webhook URL from your GitHub secret (prompts for it)
echo "Enter your TEAMS_WEBHOOK value (will not be displayed):"
read -s WEBHOOK_URL

if [ -z "$WEBHOOK_URL" ]; then
  echo "Error: No webhook URL provided"
  exit 1
fi

# Send the test message
echo "Sending test webhook message..."
curl -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL"

echo -e "\nWebhook test complete! Check your Teams channel for the message."
