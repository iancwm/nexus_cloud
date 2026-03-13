#!/bin/bash
# Verify Hosted Coder Server Health

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

URL="https://${DOMAIN}/api/v2/buildinfo"
echo "Verifying Coder server at ${URL}..."

MAX_RETRIES=30
COUNT=0

until curl -s -f "$URL" > /dev/null; do
    echo "  [$(date +%T)] Waiting for server... (Attempt $COUNT/$MAX_RETRIES)"
    sleep 10
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "  ❌ Timeout waiting for server. Check ALB and EC2 status."
        exit 1
    fi
done

echo "✅ SUCCESS: Coder server is live and responding!"
curl -s "$URL" | jq .
