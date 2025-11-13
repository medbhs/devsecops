# DevSecOps TP1–TP6 — Project Documentation

Last updated: 2025-11-12

This document explains what the repository contains, what was implemented for each training phase (TP1–TP6), how to test and demonstrate the environment, and — most importantly — the security controls implemented and why they matter.

## TL;DR / Project summary

This project converts a 6-step DevOps training set (TP1..TP6) into an end-to-end DevSecOps demo environment running on Ubuntu 24.04. It deploys and wires together host hardening, CI tools, static/secret scans, image scanning, runtime detection, and admission-control policies to show how security can be introduced across the SDLC and runtime.

Key outcomes you can demonstrate now (artifacts in `artifacts/`):
- Host integrity baseline using AIDE (`tp1/aide-check.txt`).
- Static analysis and secrets scanning via SonarQube, Gitleaks, and OWASP Dependency-Check (reports in repo).
- Image scanning with Trivy (`tp3/trivy-report.json`).
- Image signing tooling installed (Cosign scripts in `tp3/`).
- Runtime intrusion detection with Falco (logs and example alert in `tp5/`).
- Admission control in Kubernetes using OPA Gatekeeper with a ConstraintTemplate that blocks `:latest` images and unapproved registries (evidence: `tp6/gatekeeper-test.txt`).

## Project layout (important files)

- `tp1/` — host hardening and integrity
  - `harden_ubuntu24.sh` — hardening script (auditd, UFW, fail2ban, etc.)
  - `verify_baseline.sh` — verification helper
  - `aide-check.txt` — saved AIDE check output (generated)

- `tp2/` — CI and code quality
  - `sonarqube-docker-compose.yml` — SonarQube + DB compose
  - `gitleaks_scan.sh` — run secrets scanning
  - `dependency-check-report/` — OWASP Dependency-Check outputs

- `tp3/` — container/image security
  - `trivy_scan.sh`, `trivy-report.json` — Trivy scan and report
  - `cosign_install.sh` / `cosign_sign_image.sh` — cosign helpers

- `tp5/` — runtime security
  - `install_falco.sh` — falco install helper (falling back to container)
  - `falco-detection.log` — captured falco container logs
  - `falco-alert-example.txt` — extracted alert examples for demo

- `tp6/` — Kubernetes admission policies
  - `gatekeeper_constraint_template_image_vuln.yaml` — ConstraintTemplate (Rego)
  - `gatekeeper_constraint_image_vuln.yaml` — Constraint instance
  - `gatekeeper-test.yaml` — sample Deployment (nginx:latest)
  - `gatekeeper-test.txt` — recorded webhook denial output

- `verification-summary.txt` — combined verification script outputs
- `DEMO_README.md` — short runbook (also created)
- `artifacts/` — collected evidence files for sharing
- `devsecops-demo-<date>.tar.gz` — tarball created on Desktop (packaged artifacts)


## What was implemented (TP-by-TP, short)

- TP1 (Host hardening & integrity):
  - Applied a simple baseline hardening script (UFW firewall, fail2ban, auditd). AIDE was configured and the initial database was created. Output saved to `tp1/aide-check.txt`.

- TP2 (CI & code quality):
  - SonarQube is packaged via Docker Compose and was started. Gitleaks and Dependency-Check were run against the repository to produce reports. These supply the SAST/SCA aspects.

- TP3 (Image scanning & signing):
  - Trivy was used to scan `alpine:latest` as an example. The JSON report is `tp3/trivy-report.json`. Cosign was installed and helper scripts are available to sign images.

- TP4 (Quality gates):
  - SonarQube provides quality gates and can be integrated into Jenkins pipelines. Jenkins is running as a systemd service in the environment.

- TP5 (Runtime security):
  - Falco runs as a privileged Docker container fallback on this host. Logs and an extracted alert are provided in `tp5/`.

- TP6 (Kubernetes policy enforcement):
  - OPA Gatekeeper installed on the Minikube cluster and a ConstraintTemplate + Constraint deny `:latest` images and images from unapproved registries. An attempt to create `nginx:latest` was blocked and the denial was saved to `tp6/gatekeeper-test.txt`.


## How to test & demo (step-by-step, quick)

Open a terminal with zsh and cd to the project root:

```bash
cd ~/Desktop/DevOps/DevSecOps
```

Pre-demo quick checks:

```bash
# Docker and minikube running?
docker ps --format 'table {{.Names}}	{{.Image}}	{{.Status}}' | sed -n '1,200p'
systemctl is-active jenkins || true
kubectl config current-context
kubectl get nodes -o wide
```

Demo flow (keep each step short — show a saved artifact instead of re-running long scans):

1) AIDE baseline (TP1)

```bash
# Show saved AIDE check
less tp1/aide-check.txt
# Or run live (requires sudo)
sudo aide --config /etc/aide/aide.conf --check | tail -n 40
```

2) Trivy image scan (TP3)

```bash
# View the JSON report with jq (show top vulnerabilities)
jq '.Results[] | {Target,Class,Type,Vulnerabilities: (.Vulnerabilities|length)}' tp3/trivy-report.json | head -n 20
# Or pretty print a few entries
jq '.Results[0].Vulnerabilities[0:5]' tp3/trivy-report.json
```

3) Gatekeeper enforcement (TP6)

```bash
# Attempt to create the demo Deployment (it should be denied)
kubectl apply -f tp6/gatekeeper-test.yaml
# Show recorded denial
less tp6/gatekeeper-test.txt
# Show constraint status
kubectl get constraints --all-namespaces
kubectl describe -n gatekeeper-system constraint <constraint-name> || true
```

4) Falco runtime detection (TP5)

```bash
# Trigger a short container exec
docker run -d --name falco-demo alpine:3.18 sleep 300
docker exec falco-demo sh -c "id"
# Wait a second then show the alert example
tail -n 80 tp5/falco-detection.log
less tp5/falco-alert-example.txt
```

5) SonarQube / Jenkins (TP2/TP4)

- Open a browser to SonarQube: `http://localhost:9000` (API was observed up earlier).
- Open Jenkins: `http://localhost:8080` (initial admin password: `/var/lib/jenkins/secrets/initialAdminPassword`).

6) Artifacts and packaging

```bash
ls -lah artifacts
ls -lah ~/Desktop/devsecops-demo-$(date +%Y%m%d).tar.gz
```


## Security controls implemented (mapping and purpose)

This section lists the controls that were implemented, why they were chosen, and where to find the evidence/config.

- Host integrity (AIDE)
  - Why: Detect unauthorized modifications to critical files and binaries on the host.
  - What: AIDE config and initial DB created. Evidence: `tp1/aide-check.txt` and `/var/lib/aide/aide.db`.

- Host hardening (UFW, auditd, fail2ban)
  - Why: Basic network hardening, monitoring, and automated blocking of suspicious login attempts.
  - What: `tp1/harden_ubuntu24.sh` performs these tasks. Review the script before applying in production.

- SAST / Quality gates (SonarQube)
  - Why: Find code smells, bugs, and apply quality gates that are enforceable in pipelines.
  - What: `tp2/sonarqube-docker-compose.yml`; results are accessible via Sonar web UI. Integrate with Jenkins pipeline for automation.

- Secrets scanning (Gitleaks)
  - Why: Detect accidental commits of secrets or credentials.
  - Evidence: gitleaks report (`tp2/gitleaks-report.json` if present).

- Software Composition Analysis (Dependency-Check)
  - Why: Detect vulnerable libraries in your projects.
  - Evidence: `dependency-check-report/` produced by the run.

- Image scanning (Trivy)
  - Why: Detect CVEs in container images before runtime.
  - What: Trivy JSON output at `tp3/trivy-report.json`.

- Image signing (Cosign)
  - Why: Allow image provenance verification as part of pipeline enforcement.
  - What: Cosign install helper and example scripts found under `tp3/`.

- Admission control / policy (OPA Gatekeeper)
  - Why: Prevent insecure or non-compliant images from running in the cluster. Enforce org policies centrally.
  - What: `tp6/gatekeeper_constraint_template_image_vuln.yaml` and `tp6/gatekeeper_constraint_image_vuln.yaml`. Evidence: `tp6/gatekeeper-test.txt` (denial output).

- Runtime detection (Falco)
  - Why: Detect suspicious process activity, unexpected network connections, and file writes while containers run.
  - What: Falco was deployed as a privileged container (fallback). Logs and example alerts: `tp5/falco-detection.log` and `tp5/falco-alert-example.txt`.


## Limitations & recommendations

- Falco installation was done via a privileged container fallback because the host kernel / environment restricted repository-based installation in this environment. For production use install Falco via the system package or kernel modules to enable full BPF tracepoints.
- Many tools run in containers in this demo. For production, aim for centralized logging (ELK/EFK), alerting, and hardened hosts.
- Gatekeeper policy is example-level; extend regressions tests and more granular rules for registry allowlists, CVE thresholds, SBOM checks, and cosign verification.
- Consider integrating signed-image verification in admission control (Cosign + OPA) so only signed images are allowed.


## Next steps (recommended roadmap)

1. Replace Falco container fallback with host install and centralize alerts into Grafana/Loki or SIEM.
2. Wire scanner runs into Jenkins pipeline and enforce quality gates before merge.
3. Add automated image signing with Cosign and block unsigned images in Gatekeeper.
4. Expand Gatekeeper policies to include SBOM checks and CVE thresholds via custom Rego rules.
5. Add CI job that runs Dependency-Check and uploads results to a central report (or Sonar if integrated).


## Quick troubleshooting notes

- If SonarQube fails to start, inspect Docker Compose logs: `docker compose -f tp2/sonarqube-docker-compose.yml logs`.
- If Gatekeeper gives `no matches for ConstraintTemplate`, ensure the Gatekeeper controller is installed first: `kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml` then re-apply the ConstraintTemplate/Constraint.
- If Falco shows BPF/tracepoint errors, check kernel version and `/lib/modules` mounted into the container; host install is recommended.


## Where to find the artifacts

- All demo evidence is under `artifacts/` in the project root. The tarball was created on the Desktop as `devsecops-demo-YYYYMMDD.tar.gz`.
- Individual files:
  - `tp1/aide-check.txt`
  - `tp3/trivy-report.json`
  - `tp5/falco-detection.log`, `tp5/falco-alert-example.txt`
  - `tp6/gatekeeper-test.txt`
  - `verification-summary.txt`
  - `DEMO_README.md`


## How to reproduce the full demo automatically (optional)

I can produce a single script (demo-run.sh) that runs the AIDE check, runs a Trivy scan, attempts to apply the Gatekeeper test manifest, triggers a Falco exec test, and collects logs. If you want that, tell me and I will add `demo-run.sh` to the repo and run it one time so you have a timestamped log.


## Contact / credits

This demo and documentation were prepared from the TP1–TP6 training materials and extended to create a small DevSecOps demo on Ubuntu 24.04. If you want slides or a scripted demo-runner, ask and I will create them.
