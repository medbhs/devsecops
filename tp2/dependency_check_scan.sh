#!/usr/bin/env bash
# Run OWASP Dependency-Check via Docker against a target dir
set -euo pipefail
TARGET_DIR="${1:-.}"
OUTPUT_DIR="${2:-$PWD/dependency-check-report}"
mkdir -p "$OUTPUT_DIR"

echo "[+] Running OWASP Dependency-Check on $TARGET_DIR -> $OUTPUT_DIR"
docker run --rm -v "$PWD":"/src" -v "$OUTPUT_DIR":"/report" owasp/dependency-check:latest --project "lab-scan" --scan "/src/$TARGET_DIR" --format ALL --out "/report"

echo "Reports in: $OUTPUT_DIR"
