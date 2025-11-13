# DevSecOps Platform Architecture (Ubuntu 24.04 Local Lab)

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DevSecOps Transformation Platform                     │
│                       (6-Stage Training Lab)                             │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   TP1: Secure    │  Host Hardening + Audit Logging (UFW, Fail2Ban, AIDE)
│   Foundation     │  ↓ Security Baseline (SSH, Sysctl, Audit Rules)
└──────────────────┘
         │
         ↓
┌──────────────────┐
│   TP2: Secure    │  Git Repository → Jenkins Pipeline
│   CI Pipeline    │  ├─ Secret Scanning (Gitleaks)
└──────────────────┘  ├─ SAST (SonarQube)
         │            └─ Dependency Check (OWASP)
         ↓
┌──────────────────┐
│   TP3: Secure    │  Docker Image Build → Trivy Scan → Cosign Sign
│   Container      │  ├─ Vulnerability Scanning (Trivy)
│   Delivery       │  └─ Image Signing (Cosign/Sigstore)
└──────────────────┘
         │
         ↓
┌──────────────────┐
│   TP4: Enhanced  │  SonarQube Quality Gates + Security Rules
│   Code Quality   │  ├─ Security-Focused Rules
└──────────────────┘  ├─ License Scanning (ScanCode/FOSSology)
         │            └─ Automated Debt Tracking
         ↓
┌──────────────────┐
│   TP5: Security  │  Runtime Detection + Log Aggregation
│   Monitoring     │  ├─ Falco (Runtime Threat Detection)
│   & Detection    │  ├─ Wazuh (SIEM/Log Correlation)
└──────────────────┘  └─ Prometheus + Grafana (Dashboards)
         │
         ↓
┌──────────────────┐
│   TP6: K8s       │  Hardened Deployment + Policy Enforcement
│   Security       │  ├─ RBAC Policies
│   Hardening      │  ├─ Network Policies (Default Deny)
└──────────────────┘  ├─ OPA Gatekeeper (Admission Control)
                      ├─ Pod Security Standards
                      └─ Secrets Encryption
```

## Security Layer Mapping

| TP | Layer | Controls | Tools |
|----|-------|----------|-------|
| **TP1** | **Host** | OS hardening, SSH, Firewall, Audit, File Integrity | UFW, Fail2Ban, AIDE, Auditd, Sysctl |
| **TP2** | **CI/Build** | Secrets scanning, SAST, Dependency analysis | Gitleaks, SonarQube, OWASP Dep-Check |
| **TP3** | **Container** | Image vulnerability scan, Signing, Registry | Trivy, Cosign, Docker Hub/Harbor |
| **TP4** | **Code Quality** | Security rules, Gates, License compliance | SonarQube, Dependency-Check, ScanCode |
| **TP5** | **Runtime** | Threat detection, Log aggregation, Alerting | Falco, Wazuh, Prometheus, Grafana |
| **TP6** | **Orchestration** | RBAC, Network policies, Admission control, Encryption | K8s, OPA Gatekeeper, Pod Security |

## Tool Integration Flow

```
Source Code (Git)
    ↓
[Secret Scanning - Gitleaks]
    ├─ FAIL → Abort build
    └─ PASS ↓
[SAST - SonarQube + Dep-Check]
    ├─ FAIL (critical) → Abort/Alert
    └─ PASS ↓
[Build - Maven/Docker]
    ├─ Compile + Unit Tests
    └─ PASS ↓
[Container Image Scan - Trivy]
    ├─ FAIL (critical vuln) → Block push
    └─ PASS ↓
[Image Sign - Cosign]
    ├─ Sign with private key
    └─ PASS ↓
[Push to Registry]
    ├─ Docker Hub/Harbor
    └─ PASS ↓
[Deploy to K8s - Minikube]
    ├─ Apply RBAC, NetworkPolicy, Gatekeeper
    ├─ PodSecurity admission
    └─ Secrets encrypted at rest ↓
[Runtime Detection - Falco]
    ├─ Monitor for anomalies
    └─ Alert → Wazuh/Grafana
```

## Data Flow with Security Checkpoints

```
┌─────────────────────────────────────────────────────────────────┐
│ CHECKPOINT 1: Code Repository                                   │
│ - Git pull trigger                                               │
│ - Secret scanning (Gitleaks)                                    │
│ - If secrets found: BLOCK + ALERT                              │
└─────────────────────────────────────────────────────────────────┘
         ↓ (approved code)
┌─────────────────────────────────────────────────────────────────┐
│ CHECKPOINT 2: Static Analysis & Build                           │
│ - SAST (SonarQube)                                              │
│ - Dependency analysis (OWASP)                                  │
│ - Quality gate enforcement                                      │
│ - Unit tests + integration tests                               │
│ - If gate FAIL: BLOCK + ALERT                                  │
└─────────────────────────────────────────────────────────────────┘
         ↓ (quality passed)
┌─────────────────────────────────────────────────────────────────┐
│ CHECKPOINT 3: Container Image Security                          │
│ - Docker image build                                            │
│ - Image vulnerability scan (Trivy)                             │
│ - If critical vuln: BLOCK + ALERT                             │
│ - Image sign (Cosign)                                          │
│ - Push to registry                                             │
└─────────────────────────────────────────────────────────────────┘
         ↓ (image secured)
┌─────────────────────────────────────────────────────────────────┐
│ CHECKPOINT 4: Kubernetes Admission Control                      │
│ - Apply K8s YAML manifests                                     │
│ - RBAC enforces user/service account permissions              │
│ - NetworkPolicy default-deny + allow rules                    │
│ - OPA Gatekeeper validates image registry/tag/vuln status    │
│ - Pod Security admission enforces restrictions                │
│ - Secrets stored encrypted (if enabled)                       │
│ - If policy violation: BLOCK + ALERT                          │
└─────────────────────────────────────────────────────────────────┘
         ↓ (pod deployed)
┌─────────────────────────────────────────────────────────────────┐
│ CHECKPOINT 5: Runtime Security Monitoring                       │
│ - Falco monitors syscalls for anomalies                        │
│ - Pod behavior monitoring                                      │
│ - Wazuh correlates logs from all sources                      │
│ - Prometheus + Grafana display metrics & alerts               │
│ - Alert on suspicious activity                                │
└─────────────────────────────────────────────────────────────────┘
```

## Component Deployment on Ubuntu 24.04

### On-Host (Ubuntu VM)
- **Jenkins**: CI/CD orchestrator (port 8080)
- **Docker**: Container runtime (built into CI agents)
- **SonarQube**: Code quality (port 9000, via Docker Compose)
- **Minikube**: Local Kubernetes cluster (IP/port varies)
- **Falco**: Runtime detection (eBPF or container)
- **Prometheus**: Metrics collection (port 9090)
- **Grafana**: Visualization (port 3000)

### Containerized (Docker)
- SonarQube + PostgreSQL (docker-compose)
- Trivy, Gitleaks, OWASP Dependency-Check scanners
- Cosign (binary or container)
- Falco (container with host mounts)
- Falcosidekick (event forwarder, optional)

### Kubernetes (Minikube)
- RBAC: Role/RoleBinding for namespace access control
- NetworkPolicy: Pod-to-pod communication control
- OPA Gatekeeper: Custom admission policies
- Pod Security: Admission controller for pod restrictions
- Secrets: Encrypted at rest (optional setup)

## Performance & Resource Targets (Dell G15 Laptop)

| Component | RAM | CPU | Disk | Notes |
|-----------|-----|-----|------|-------|
| Ubuntu Host | 2GB base | 1-2 cores | 20GB | Baseline OS |
| Jenkins + agents | 2GB | 2 cores | 10GB | CI/CD orchestration |
| Docker services | 3-4GB | 2 cores | 30GB | SonarQube, containers |
| Minikube | 2GB | 2 cores | 20GB | K8s cluster |
| Falco + Wazuh | 1-2GB | 1 core | 5GB | Monitoring/security |
| Total Recommended | 15GB | 6+ cores | 100GB | For full stack |

**Laptop Optimization**:
- Run Falco as container (not full agent)
- Wazuh optional (can use lightweight Loki instead)
- SonarQube community (not enterprise)
- Minikube single-node K8s
- Scanner images pulled on-demand

## Workflow: From Code to Secure Deployment

1. **Developer**: Commits code to Git → Jenkins webhook triggers
2. **TP1**: Agent runs on hardened Ubuntu with UFW, auditd, Fail2Ban active
3. **TP2**: Jenkins pipeline runs Gitleaks, SonarQube, Dependency-Check
   - If any gate fails: build UNSTABLE/FAIL → developer notified
4. **TP3**: Docker image built, scanned with Trivy, signed with Cosign
   - If vulnerabilities critical: image NOT pushed
5. **TP4**: SonarQube quality gate enforced; security rules applied
   - New critical/blocker issues block deployment
6. **TP5**: Container deployed to Minikube; Falco monitors runtime
   - Any anomalies logged to Wazuh; alerts in Grafana
7. **TP6**: K8s manifests validated against OPA policies; RBAC restricts access
   - Pod Security Standards enforced; secrets encrypted

## Security Compliance Mapping

- **NIST SP 800-53**: SC-7 (boundary protection), SI-2 (flaw remediation), AU-2 (audit events)
- **OWASP**: Secure SDLC practices, SAST/DAST, supply chain security
- **CIS Benchmarks**: Ubuntu 24.04 hardening, Kubernetes hardening
- **PCI-DSS**: Encryption, access control, logging/monitoring
- **ISO 27001**: InfoSec policy, incident management, audit trail

---

**Lab Environment Note**: This architecture is designed for a single-user, local training environment. For production:
- Move Wazuh + ELK to separate VMs/cloud
- Use managed Kubernetes (EKS, GKE, AKS)
- Implement multi-region, HA setups
- Connect to external SIEM/log management
- Enable enterprise features (commercial license tools)
