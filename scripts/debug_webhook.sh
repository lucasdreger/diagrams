WEBHOOK_URL="https://frostaag.webhook.office.com/webhookb2/9cfe5169-8ba4-4923-b8d5-3ceacb07866c@a8d22be6-5bda-4bd7-8278-226c60c037ed/IncomingWebhook/abc6eb0b6dec40718c68279edf44821e/8c244c0d-59d9-4113-9646-16bf549a4a64/V2GAqcWDW37bHUcSPdN2Xwla4SyxujUouERQAlidZrsiI1"

# Create a simple payload
PAYLOAD="{
  \"@type\": \"MessageCard\",
  \"@context\": \"http://schema.org/extensions\",
  \"themeColor\": \"FF9900\",
  \"summary\": \"Debug Test\",
  \"sections\": [
    {
      \"activityTitle\": \"⚙️ Debug Webhook Test\",
      \"activitySubtitle\": \"$(date +\"%d.%m.%Y %H:%M:%S\")\",
      \"activityImage\": \"https://github.com/lucasdreger.png?size=40\",
      \"facts\": [
        {
          \"name\": \"Testing\",
          \"value\": \"Direct webhook URL\"
        }
      ],
      \"text\": \"This is a direct test with hard-coded webhook URL.\"
    }
  ]
}"

# Send the test message
echo "Sending debug webhook test..."
curl -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL"

echo -e "
Debug test complete!"
