#!/usr/bin/env bash
set -euo pipefail

check() {
  local name="$1" url="$2" pattern="${3:-}"
  local body
  body="$(curl -fsS "$url")"
  if [[ -n "$pattern" ]] && ! grep -q "$pattern" <<<"$body"; then
    echo "FAIL: $name (pattern '$pattern' not found)" >&2
    exit 1
  fi
  echo "OK: $name"
}

echo "Checking observability stack..."
check "App health" "http://localhost:3000/health"
check "App metrics" "http://localhost:3000/metrics" "app_requests_total"
check "Prometheus" "http://localhost:9090/-/ready"
check "Grafana" "http://localhost:3000/api/health" || check "Grafana" "http://localhost:3001/api/health"
check "Loki" "http://localhost:3100/ready"

curl -fsS "http://localhost:3000/api/data" >/dev/null
echo "OK: Sample traffic sent. Run ./scripts/trigger-alert.sh to test alerting."
echo "All checks passed."
