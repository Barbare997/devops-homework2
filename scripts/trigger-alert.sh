#!/usr/bin/env bash
# Sends sustained 500 responses so the error rate stays above 5/min long enough to fire the alert.

ROUNDS="${1:-12}"
PER_ROUND="${2:-8}"
PAUSE="${3:-5}"
URL="http://localhost:3000/api/error"

echo "Hitting ${URL} (${PER_ROUND} requests x ${ROUNDS} rounds)..."

for ((round=1; round<=ROUNDS; round++)); do
  for ((i=1; i<=PER_ROUND; i++)); do
    curl -s -o /dev/null "$URL" || true
  done
  echo "Round ${round}/${ROUNDS} done"
  sleep "$PAUSE"
done

echo ""
echo "Done. Refresh http://localhost:9090/alerts every 15-20s."
echo "Expect Pending first, then FIRING after about a minute."
