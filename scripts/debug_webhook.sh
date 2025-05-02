#!/bin/zsh
# Debug test for Teams webhook - this file won't be committed to the repo
# 
# Instructions:
#
# 1. Add your Teams webhook URL on the line below between the quotes
WEBHOOK_URL=""
#
# 2. Run this script:
#    zsh debug_webhook.sh
#
# 3. Delete this file when done testing
#

if [ -z "$WEBHOOK_URL" ]; then
  echo "Please edit this file and add your webhook URL between the quotes"
  exit 1
fi

# Create a simple payload
PAYLOAD='{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "FF9900",
  "summary": "Debug Test",
  "sections": [
    {
      "activityTitle": "⚙️ Debug Webhook Test",
      "activitySubtitle": "'$(date +'%d.%m.%Y %H:%M:%S')'",
      "facts": [
        {
          "name": "Testing",
          "value": "Direct webhook URL"
        }
      ],
      "text": "This is a direct test with hard-coded webhook URL. If this works but the GitHub action doesn'\''t, there'\''s an issue with how the secret is accessed."
    }
  ]
}'

# Send the test message
echo "Sending debug webhook test..."
curl -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL"

echo -e "\nDebug test complete!"
