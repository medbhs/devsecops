#!/usr/bin/env bash
# Import SonarQube quality profile or set quality gate using SonarQube API
set -euo pipefail
SONAR_HOST=${SONAR_HOST:-http://localhost:9000}
SONAR_TOKEN=${SONAR_TOKEN:-}
PROFILE_XML="${1:-sonar_security_profile.xml}"
GATE_JSON="${2:-sonar_quality_gate.json}"

if [ -z "$SONAR_TOKEN" ]; then
  echo "Export SONAR_TOKEN env var with a user token that has admin rights in SonarQube" >&2
  exit 2
fi

# Import profile (if CLI/API supports). SonarQube doesn't have a direct import via API for profiles,
# but you can use the web API to create/activate rules or use sonar-scanner to push settings.
# This script will create a quality gate and set it as default.

# Create quality gate
echo "[+] Creating quality gate"
GATE_ID=$(curl -s -u "$SONAR_TOKEN": "$SONAR_HOST/api/qualitygates/create?name=$(jq -r .name <$GATE_JSON)" | jq -r .id)
if [ -z "$GATE_ID" ] || [ "$GATE_ID" = "null" ]; then
  echo "Failed to create quality gate or gate already exists"
else
  echo "Created gate id: $GATE_ID"
fi

# Add conditions
echo "[+] Adding conditions"
jq -c '.conditions[]' < $GATE_JSON | while read -r cond; do
  metric=$(echo "$cond" | jq -r .metric)
  op=$(echo "$cond" | jq -r .op)
  error=$(echo "$cond" | jq -r .error)
  # Translate op to API operator (GT -> GT)
  curl -s -u "$SONAR_TOKEN": "$SONAR_HOST/api/qualitygates/create_condition?gateId=$GATE_ID&metric=$metric&op=$op&error=$error" >/dev/null
done

# Set as default
curl -s -u "$SONAR_TOKEN": "$SONAR_HOST/api/qualitygates/set_as_default?id=$GATE_ID" >/dev/null

echo "[+] Quality gate created and set as default"
