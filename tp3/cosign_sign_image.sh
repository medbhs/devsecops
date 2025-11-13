#!/usr/bin/env bash
# Sign an image using cosign. If no key exists, generates a key pair protected by COSIGN_PASSWORD env var.
set -euo pipefail
IMAGE="${1:-}"
if [ -z "$IMAGE" ]; then
  echo "Usage: $0 image:tag" >&2
  exit 2
fi

# Ensure cosign present
if ! command -v cosign >/dev/null 2>&1; then
  echo "cosign not found - installing locally"
  sudo bash ./cosign_install.sh
fi

# Key pair
KEY_DIR="${COSIGN_KEY_DIR:-$HOME/.cosign}"
PRIVATE_KEY="$KEY_DIR/cosign.key"
PUBLIC_KEY="$KEY_DIR/cosign.pub"
mkdir -p "$KEY_DIR"

if [ ! -f "$PRIVATE_KEY" ]; then
  echo "[+] Generating cosign key pair"
  if [ -z "${COSIGN_PASSWORD:-}" ]; then
    echo "Set COSIGN_PASSWORD env var to protect the private key (recommended)."
  fi
  COSIGN_PASSWORD_ENV="${COSIGN_PASSWORD:-}" cosign generate-key-pair || true
  # cosign generate-key-pair writes cosign.key and cosign.pub in current dir; move them
  mv cosign.key "$PRIVATE_KEY" 2>/dev/null || true
  mv cosign.pub "$PUBLIC_KEY" 2>/dev/null || true
fi

echo "[+] Signing image $IMAGE"
# Use key to sign
COSIGN_PASSWORD_ENV="${COSIGN_PASSWORD:-}" cosign sign --key "$PRIVATE_KEY" "$IMAGE"

# Verify
cosign verify --key "$PUBLIC_KEY" "$IMAGE" || true

echo "[+] Image signed and verification attempted"
