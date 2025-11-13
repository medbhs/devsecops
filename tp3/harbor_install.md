Harbor Optional Install (Resource-Heavy)

Harbor provides a private registry with vulnerability scanning and signing integration. It's heavy for a laptop; recommended only if you have sufficient resources.

Quick install using Harbor's installer:

1) Ensure Docker and docker-compose are installed.
2) Download harbor-offline-installer from GitHub releases.
3) Edit `harbor.yml` and set hostname and admin password.
4) Run `sudo ./install.sh` and wait for services to start.
5) Access Harbor web UI and configure projects, robot accounts, and connect scanners (Clair/Trivy) if needed.

Notes for lab:
- Harbor requires at least 4GB RAM; tune docker resources accordingly in Docker Desktop or host.
- Alternatively, use Docker Hub private repos for simplicity, and rely on Trivy/Cosign for scanning/signing.
