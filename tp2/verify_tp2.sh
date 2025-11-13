#!/usr/bin/env bash
set -euo pipefail

echo "[+] Verifying TP2 scanners"
# Gitleaks
bash ./gitleaks_scan.sh . || true
# Dependency check
bash ./dependency_check_scan.sh . || true
# Sonar will require SONAR_LOGIN env var
if [ -n "${SONAR_LOGIN:-}" ]; then
  export SONAR_LOGIN
  bash ./sonar_scan.sh . || true
else
  echo "SONAR_LOGIN not set - skipping Sonar scan"
fi

echo "[+] Verification complete. Check reports: gitleaks-report.json, dependency-check-report, Sonar logs (if run)"
