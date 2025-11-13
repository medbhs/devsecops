#!/usr/bin/env bash
# Verify Falco is running and Falcosidekick metrics are available
set -euo pipefail

echo "[+] Checking Falco service"
if systemctl is-active --quiet falco; then
  echo "Falco is active"
else
  echo "Falco is not active - check /var/log/falco or systemctl status falco"; exit 2
fi

# Check Falco logs for recent events (last 20 lines)
sudo journalctl -u falco -n 20 --no-pager || true

# Check falcosidekick metrics endpoint
if curl -sSf http://localhost:2801/metrics >/dev/null 2>&1; then
  echo "Falcosidekick metrics available at http://localhost:2801/metrics"
else
  echo "Falcosidekick metrics not reachable at http://localhost:2801/metrics - ensure container running or adjust firewall"
fi

echo "[+] Verify completed"
