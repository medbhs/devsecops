#!/usr/bin/env bash
# Install Falco on Ubuntu 24.04 and configure JSON output + local rules
set -euo pipefail

echo "[+] Adding Falco apt repository (attempt)"
set +e
curl -fsSL https://falco.org/repo/falcosecurity-archive.key | sudo gpg --dearmor -o /usr/share/keyrings/falcosecurity-archive-keyring.gpg
RC=$?
set -e
if [ $RC -eq 0 ]; then
	echo "[+] Falco GPG key fetched"
	echo "deb [signed-by=/usr/share/keyrings/falcosecurity-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | sudo tee /etc/apt/sources.list.d/falcosecurity.list
	sudo apt update
	if sudo apt install -y falco; then
		echo "[+] Falco installed via apt"
		FALCO_CONF=/etc/falco/falco.yaml
		sudo cp $FALCO_CONF ${FALCO_CONF}.orig || true
		sudo sed -i 's/^json_output: .*/json_output: true/' $FALCO_CONF || true
		sudo sed -i 's/^json_include_output_property: .*/json_include_output_property: true/' $FALCO_CONF || true
		sudo mkdir -p /etc/falco
		sudo cp ./falco_rules.custom.yaml /etc/falco/falco_rules.local.yaml
		sudo systemctl enable --now falco || true
		echo "[+] Falco service enabled"
		sudo systemctl status falco --no-pager || true
		echo "[+] To forward Falco events to Prometheus, run Falcosidekick (see falcosidekick_setup.md)"
		exit 0
	else
		echo "[!] apt install falco failed, falling back to Docker mode"
	fi
else
	echo "[!] Could not fetch Falco GPG key (repo may be unavailable). Falling back to Docker deployment."
fi

# Fall back: run Falco in Docker (container) for lab environments
echo "[+] Running Falco as a Docker container (fallback mode)"
sudo docker pull falcosecurity/falco:latest || true
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo mkdir -p /etc/falco
if [ -f "$SCRIPT_DIR/falco_rules.custom.yaml" ]; then
	sudo cp "$SCRIPT_DIR/falco_rules.custom.yaml" /etc/falco/falco_rules.local.yaml || true
else
	echo "[!] Custom Falco rule file not found in $SCRIPT_DIR; skipping copy"
fi

# Run container with necessary host mounts and privileges
if sudo docker ps --filter "name=falco" --format '{{.Names}}' | grep -q falco; then
	echo "Falco container already running"
else
	sudo docker run -d --name falco --privileged \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		-v /dev:/host/dev:ro \
		-v /proc:/host/proc:ro \
		-v /boot:/host/boot:ro \
		-v /etc/falco:/etc/falco:ro \
		falcosecurity/falco:latest
	echo "Falco container started"
fi

echo "[+] Falco (docker) running. To forward events to Falcosidekick or other systems, follow falcosidekick_setup.md"
