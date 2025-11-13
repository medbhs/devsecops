#!/usr/bin/env bash
# Run SonarScanner via Docker against a target directory
set -euo pipefail
TARGET_DIR="${1:-.}"
SONAR_HOST_URL="${SONAR_HOST_URL:-http://localhost:9000}"
SONAR_LOGIN="${SONAR_LOGIN:-}"

if [ -z "$SONAR_LOGIN" ]; then
  echo "SONAR_LOGIN is not set. Export SONAR_LOGIN with your token and retry." >&2
  exit 2
fi

echo "[+] Running SonarScanner against $TARGET_DIR -> SonarQube: $SONAR_HOST_URL"

docker run --rm -v "$PWD":"/usr/src" -w /usr/src sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=lab-project \
  -Dsonar.sources=. \
  -Dsonar.host.url="$SONAR_HOST_URL" \
  -Dsonar.login="$SONAR_LOGIN"
