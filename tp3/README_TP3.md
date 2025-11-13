TP3: Secure Container Delivery (Trivy + Cosign)

Overview
--------
This TP3 package adds container image scanning and signing to your CI/CD pipeline. It uses Trivy for vulnerability scanning and Cosign (Sigstore) for image signing.

Included files
- `trivy_scan.sh` - run Trivy against a local image or directory
- `cosign_install.sh` - installs Cosign on Ubuntu 24.04
- `cosign_sign_image.sh` - sign an image using Cosign key-pair or keyless
- `dockerfile_best_practices.md` - Dockerfile hardening tips
- `harbor_install.md` - optional Harbor private registry install notes (resource-heavy)

Quick run examples

1) Install Cosign and Trivy (COSIGN):
```bash
cd tp3
sudo bash ./cosign_install.sh
# Install trivy via apt or use docker image
sudo apt install -y trivy || true
```

2) Build an image and scan it:

```bash
docker build -t myapp:lab .
bash ./trivy_scan.sh image myapp:lab
```

3) Sign the image with Cosign (generates key if missing):

```bash
export COSIGN_PASSWORD="mypass"
bash ./cosign_sign_image.sh myapp:lab
```

Notes
- Trivy supports fast scans; to meet performance targets, use local DB cache and the `--cache-dir` option.
- Cosign supports keyless signing via OIDC; this script defaults to key-pair to keep lab simple.
