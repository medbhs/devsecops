#!/usr/bin/env bash
# Install Docker, docker-compose (plugin), and pull scanner images (Ubuntu 24.04)
set -euo pipefail

echo "[+] Installing prerequisites"
apt update
apt install -y ca-certificates curl gnupg lsb-release

echo "[+] Installing Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker "$SUDO_USER"
fi

echo "[+] Pulling scanner images"
docker pull sonarsource/sonar-scanner-cli:latest
docker pull owasp/dependency-check:latest
docker pull zricethezav/gitleaks:latest

echo "[+] Done. You may need to log out/in for Docker group changes to apply."
