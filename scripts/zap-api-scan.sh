#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  zap-api-scan.sh --target "http://127.0.0.1:8000" --openapi "/openapi.json" \
                  --rules ".zap/rules.tsv" --out "artifacts/zap"

Notes:
  - Requires Docker and uses --network host to reach the app at 127.0.0.1.
  - ZAP_FAIL_ON env var controls failing level: "high" or "medium" (default: medium).
USAGE
}

TARGET=""
OPENAPI_PATH="/openapi.json"
RULES_FILE=""
OUT_DIR="artifacts/zap"
FAIL_ON="${ZAP_FAIL_ON:-medium}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2}"; shift 2 ;;
    --openapi) OPENAPI_PATH="${2}"; shift 2 ;;
    --rules) RULES_FILE="${2}"; shift 2 ;;
    --out) OUT_DIR="${2}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  echo "ERROR: --target is required"; exit 2
fi

mkdir -p "${OUT_DIR}"

# Build ZAP arguments
REPORT_HTML="${OUT_DIR}/zap-api-report.html"
REPORT_JSON="${OUT_DIR}/zap-api-report.json"
REPORT_MD="${OUT_DIR}/zap-api-report.md"

RULES_ARG=()
if [[ -n "${RULES_FILE}" && -f "${RULES_FILE}" ]]; then
  RULES_ARG=(-z "-configfile /zap/wrk/rules.tsv")
  cp "${RULES_FILE}" "${OUT_DIR}/rules.tsv"
else
  # still mount an empty file to satisfy the -z path if not provided
  touch "${OUT_DIR}/rules.tsv"
  RULES_ARG=(-z "-configfile /zap/wrk/rules.tsv")
fi

# Run ZAP API scan (OpenAPI-aware)
docker run --rm --network host \
  -v "$(pwd)/${OUT_DIR}:/zap/wrk" \
  owasp/zap2docker-stable zap-api-scan.py \
  -t "${TARGET}${OPENAPI_PATH}" \
  -f openapi \
  -r "/zap/wrk/$(basename "${REPORT_HTML}")" \
  -J "/zap/wrk/$(basename "${REPORT_JSON}")" \
  -w "/zap/wrk/$(basename "${REPORT_MD}")" \
  "${RULES_ARG[@]}"

# Simple gating: fail on High (or Medium+) risk alerts
risk_threshold=1 # 3=High, 2=Medium, 1=Low, 0=Info (ZAP risk scale); we will map based on $FAIL_ON
if [[ "${FAIL_ON}" == "high" ]]; then
  risk_threshold=3
elif [[ "${FAIL_ON}" == "medium" ]]; then
  risk_threshold=2
fi

echo "Evaluating ZAP results (threshold=${FAIL_ON})..."
# A very small jq-free parser using grep/sed to count High/Medium alerts from the Markdown summary:
HIGHS=$(grep -iE 'High Risk' "${REPORT_MD}" | sed -E 's/[^0-9]*([0-9]+).*/\1/' | head -n1 || echo "0")
MEDS=$(grep -iE 'Medium Risk' "${REPORT_MD}" | sed -E 's/[^0-9]*([0-9]+).*/\1/' | head -n1 || echo "0")

HIGHS=${HIGHS:-0}
MEDS=${MEDS:-0}

if [[ ${risk_threshold} -ge 3 && ${HIGHS} -gt 0 ]]; then
  echo "❌ Failing: ${HIGHS} High-risk ZAP alerts found."
  exit 1
elif [[ ${risk_threshold} -ge 2 && ( ${HIGHS} -gt 0 || ${MEDS} -gt 0 ) ]]; then
  echo "❌ Failing: ${HIGHS} High / ${MEDS} Medium ZAP alerts found."
  exit 1
fi

echo "✅ ZAP gating passed (High=${HIGHS}, Medium=${MEDS}). Reports at ${OUT_DIR}/"
