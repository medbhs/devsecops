#!/usr/bin/env bash
# Parse OWASP Dependency-Check report and upload as artifact or to Sonar (if using dependency-check plugin)
set -euo pipefail
REPORT_DIR="${1:-./dependency-check-report}"
SONAR_TOKEN=${SONAR_TOKEN:-}
SONAR_HOST=${SONAR_HOST:-http://localhost:9000}
PROJECT_KEY=${PROJECT_KEY:-lab-project}

if [ ! -d "$REPORT_DIR" ]; then
  echo "Dependency-Check report dir not found: $REPORT_DIR" >&2
  exit 2
fi

# Option: Archive the reports so Jenkins can attach them
# For SonarQube: there is a dependency-check plugin which can ingest the XML report.
# Here we'll simply print where the reports are and optionally call Sonar action if plugin configured.

echo "[+] Dependency-Check reports located at: $REPORT_DIR"

# If sonar token present and plugin configured, you could upload via sonar scanner properties
if [ -n "$SONAR_TOKEN" ]; then
  echo "SONAR_TOKEN available - you can configure the Dependency-Check plugin in Sonar to pick up the XML report"
fi

echo "[+] Done"
