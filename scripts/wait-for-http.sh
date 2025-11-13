#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://127.0.0.1:8000/health}"
TIMEOUT="${2:-60}"

echo "Waiting for $URL (timeout=${TIMEOUT}s)..."
end=$((SECONDS + TIMEOUT))
until curl -fsS "$URL" >/dev/null 2>&1; do
  if [ $SECONDS -ge $end ]; then
    echo "ERROR: Timeout waiting for $URL"
    exit 1
  fi
  sleep 1
done
