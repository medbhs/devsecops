#!/usr/bin/env bash
# Trivy scanning helper
# Usage:
#  bash trivy_scan.sh image <image-name>
#  bash trivy_scan.sh fs <path>
set -euo pipefail
MODE="${1:-image}"
TARGET="${2:-.}"
OUTDIR="${3:-$PWD/trivy-report}"
mkdir -p "$OUTDIR"

# default timeout to keep scan short (2 minutes)
TIMEOUT=120s

if [ "$MODE" = "image" ]; then
  IMAGE="$TARGET"
  echo "[+] Scanning image: $IMAGE"
  # Use dockerized trivy if host doesn't have it
  if command -v trivy >/dev/null 2>&1; then
    trivy image --quiet --exit-code 0 --format json -o "$OUTDIR/trivy-image-report.json" --timeout $TIMEOUT "$IMAGE" || true
  else
    docker run --rm -v $OUTDIR:/report aquasec/trivy:latest image --quiet --format json -o /report/trivy-image-report.json --timeout $TIMEOUT "$IMAGE" || true
  fi
  echo "Report: $OUTDIR/trivy-image-report.json"
elif [ "$MODE" = "fs" ]; then
  PATH_TO_SCAN="$TARGET"
  echo "[+] Scanning filesystem: $PATH_TO_SCAN"
  if command -v trivy >/dev/null 2>&1; then
    trivy fs --quiet --format json -o "$OUTDIR/trivy-fs-report.json" --timeout $TIMEOUT "$PATH_TO_SCAN" || true
  else
    docker run --rm -v "$PWD":"/scan" -v $OUTDIR:/report aquasec/trivy:latest fs --quiet --format json -o /report/trivy-fs-report.json --timeout $TIMEOUT /scan/$PATH_TO_SCAN || true
  fi
  echo "Report: $OUTDIR/trivy-fs-report.json"
else
  echo "Unknown mode. Use 'image' or 'fs'" >&2
  exit 2
fi
