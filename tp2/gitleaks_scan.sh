#!/usr/bin/env bash
# Run Gitleaks secrets scan against a target directory
set -euo pipefail
TARGET_DIR="${1:-.}"

echo "[+] Running Gitleaks on $TARGET_DIR"
# Use Dockerized Gitleaks to avoid host installs
docker run --rm -v "$PWD":"/src" -w /src zricethezav/gitleaks:latest detect --source "$TARGET_DIR" --report-format json --report-path "/src/gitleaks-report.json" || true

echo "Report: $PWD/gitleaks-report.json"
