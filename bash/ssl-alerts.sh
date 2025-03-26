#!/bin/bash

# Usage:
## run `sudo apt install jq`
## Replace WEBHOOK_URL with: 
### Slack Incoming Webhook
### Discord Webhook
### Telegram Bot API
### Your custom webhook endpoint
## chmod +x ssl-alerts.sh
## ./ssl-alerts.sh
## Note: Use with crontab for automated runs.


# List of domains to check
DOMAINS=("example.com" "sub.example.com" "anotherdomain.com")

# Alert threshold in days
THRESHOLD=15

# Webhook URL (Replace with your actual webhook)
WEBHOOK_URL="https://your-webhook-url.com"

# Function to send webhook alert
send_webhook_alert() {
    local message="$1"
    
    # JSON payload
    payload=$(jq -n --arg text "$message" '{text: $text}')
    
    # Send alert
    curl -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL"
}

# Function to check SSL expiry
check_ssl_expiry() {
    local domain=$1
    local expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)

    if [[ -z "$expiry_date" ]]; then
        echo "ERROR: Could not retrieve SSL expiration for $domain"
        return
    fi

    # Convert expiry date to seconds since epoch
    expiry_epoch=$(date -d "$expiry_date" +%s)
    current_epoch=$(date +%s)

    # Calculate remaining days
    remaining_days=$(( (expiry_epoch - current_epoch) / 86400 ))

    echo "Domain: $domain, Expiry in $remaining_days days"

    # Send webhook alert if SSL is expiring soon
    if (( remaining_days < THRESHOLD )); then
        message="🚨 SSL WARNING: The SSL certificate for $domain expires in $remaining_days days! Renew soon."
        send_webhook_alert "$message"
        echo "Alert sent for $domain!"
    fi
}

# Loop through domains
for domain in "${DOMAINS[@]}"; do
    check_ssl_expiry "$domain"
done
