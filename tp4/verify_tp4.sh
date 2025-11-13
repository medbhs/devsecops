#!/usr/bin/env bash
# Quick verify: run scan tools and ensure quality gate can be checked (Sonar must be running)
set -euo pipefail

echo "[+] Running dependency-check integration check"
if [ -d ./dependency-check-report ]; then
  ls -la dependency-check-report || true
else
  echo "No dependency-check-report found; run TP2 dependency check first"
fi

if command -v jq >/dev/null 2>&1; then
  echo "jq found"
else
  echo "Install jq to use API helper scripts"
fi

echo "[+] Done"
