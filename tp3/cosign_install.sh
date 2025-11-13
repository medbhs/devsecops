#!/usr/bin/env bash
# Install Cosign (Sigstore) on Ubuntu 24.04
set -euo pipefail

COSIGN_VERSION="v2.2.0" # adjust as needed
ARCH=$(dpkg --print-architecture)

if command -v cosign >/dev/null 2>&1; then
  echo "cosign already installed: $(cosign version)"
  exit 0
fi

echo "[+] Installing cosign $COSIGN_VERSION"
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

case "$ARCH" in
  amd64) ARCH_DL="linux-amd64";;
  arm64) ARCH_DL="linux-arm64";;
  *) ARCH_DL="linux-amd64";;
esac

URL="https://github.com/sigstore/cosign/releases/download/$COSIGN_VERSION/cosign-$ARCH_DL"
curl -L "$URL" -o cosign
chmod +x cosign
sudo mv cosign /usr/local/bin/
cd -
rm -rf "$TMPDIR"

echo "cosign installed: $(cosign version || true)"
