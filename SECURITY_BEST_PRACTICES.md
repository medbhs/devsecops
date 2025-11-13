# Security Best Practices & Operational Guidelines

## Table of Contents
1. [Secrets Management Strategy](#secrets-management)
2. [RBAC Implementation Guidelines](#rbac-guidelines)
3. [Network Segmentation Policies](#network-segmentation)
4. [Compliance Framework Mapping](#compliance-mapping)
5. [Incident Response Procedures](#incident-response)
6. [Security Audit Checklist](#audit-checklist)

---

## Secrets Management Strategy {#secrets-management}

### Principle: Never Hardcode Secrets

#### What Are Secrets?
- Database passwords & connection strings
- API keys & tokens (AWS, GitHub, Docker Hub, SonarQube)
- TLS certificates & private keys
- OAuth credentials
- SSH keys

#### Storage Strategy by Type

| Secret Type | Lab Storage | Production Storage |
|-------------|-------------|-------------------|
| **Jenkins Credentials** | Jenkins Credentials Plugin | HashiCorp Vault / AWS Secrets Manager |
| **Container Registry** | Docker config.json (encrypted) | ECR/GCR/ACR managed credentials |
| **K8s Secrets** | etcd (with encryption enabled) | External KMS (AWS KMS, GCP KMS) |
| **SSH Keys** | ~/.ssh/ (mode 600) | Bastion host / Secrets manager |
| **API Tokens** | Jenkins env variables | External OIDC / managed identity |
| **Database Creds** | RDS/managed service auth | Native service authentication |

#### Jenkins Secrets Management
```groovy
// GOOD: Reference credentials by ID
withCredentials([
  string(credentialsId: 'sonar-token', variable: 'SONAR_LOGIN'),
  usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')
]) {
  sh 'echo "Using credentials securely"'
}

// BAD: Never embed secrets
sh 'docker login -u admin -p hardcoded_password docker.io'

// BAD: Never print secrets
sh 'echo $SONAR_LOGIN'  // Will log the token!
```

#### Kubernetes Secrets
```yaml
# Encrypt secrets at rest in etcd (enable before deploying)
# See tp6/encrypt_k8s_secrets.md

# Store secrets securely
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: default
type: Opaque
stringData:
  username: dbuser
  password: $(generate_strong_random_password)

# Reference in pods
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
```

#### Secret Rotation
```bash
# Rotate SonarQube token periodically
# 1. Generate new token in SonarQube UI
# 2. Update Jenkins credential "sonar-token"
# 3. Invalidate old token in SonarQube
# 4. Test pipeline with new token
# Timeline: Every 90 days minimum

# Rotate Docker Hub credentials
docker login -u <new_username>
# Update Jenkins credentials
# Re-encrypt config.json
```

#### Audit Secret Access
```bash
# Check who accessed secrets in Jenkins
sudo grep "credentialsId\|withCredentials" /var/log/jenkins.log

# Audit K8s secret access
kubectl audit logs | grep "secrets"

# Monitor secret exfiltration (Falco rule)
# Alert on: environment variables logged, secrets in stdout/stderr
```

---

## RBAC Implementation Guidelines {#rbac-guidelines}

### Principle: Least Privilege Access

#### RBAC Hierarchy
```
┌──────────────────────────────────────────┐
│          ClusterRole / Role              │  Defines permissions
├──────────────────────────────────────────┤
│    ClusterRoleBinding / RoleBinding      │  Assigns role to user/group
├──────────────────────────────────────────┤
│   Users / ServiceAccounts / Groups       │  Who gets access
└──────────────────────────────────────────┘
```

#### Jenkins RBAC Example
```groovy
// Create limited-privilege user for pipeline
// Jenkins → Manage Users → Create User "build-agent"
// Assign only necessary permissions:
// - View jobs in namespace
// - Build jobs
// - Read artifacts
// - NO admin, NO delete, NO configure

pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins-agent  # Limited service account
  containers:
  - name: runner
    image: ubuntu:24.04
    command:
    - cat
    tty: true
'''
    }
  }
  stages {
    stage('Build') {
      steps {
        script {
          // This runs as jenkins-agent service account
          // Limited to read pods, exec into pods, not admin
          sh 'kubectl get pods'
        }
      }
    }
  }
}
```

#### Kubernetes RBAC Example
```yaml
# Namespace-scoped admin (not cluster admin)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/logs"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devs-namespace-admin
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: namespace-admin
subjects:
- kind: Group
  name: devs
  apiGroup: rbac.authorization.k8s.io
```

#### Service Account Principle
```yaml
# Create minimal service account for applications
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-user
  namespace: default

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-read-only
  namespace: default
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-read-only-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-read-only
subjects:
- kind: ServiceAccount
  name: app-user
  namespace: default

---
# Pod using this service account
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  serviceAccountName: app-user
  containers:
  - name: app
    image: ubuntu:24.04
    command: ["sleep", "3600"]
```

#### Regular RBAC Audit
```bash
# List all RBAC bindings in cluster
kubectl get rolebindings,clusterrolebindings -A

# Check specific user/service account permissions
kubectl auth can-i get pods --as=system:serviceaccount:default:app-user

# Audit failed auth attempts
kubectl audit logs | grep -i "forbidden\|unauthorized"
```

---

## Network Segmentation Policies {#network-segmentation}

### Principle: Default Deny, Explicit Allow

#### Container Network Isolation (Docker)
```bash
# Create isolated network for sensitive services
docker network create --driver bridge \
  --opt "com.docker.network.bridge.enable_ip_masquerade=true" \
  devsecops-secure

# Run services on isolated network
docker run -d --name postgres --network devsecops-secure \
  postgres:latest

docker run -d --name app --network devsecops-secure \
  ubuntu:24.04 sleep 3600

# Services NOT on this network cannot reach postgres
```

#### Kubernetes NetworkPolicy (Default Deny)
```yaml
---
# 1. Default deny ALL ingress/egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# 2. Allow DNS (required for pod communication)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53

---
# 3. Allow frontend-to-backend communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080

---
# 4. Allow ingress from external load balancer
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 443
```

#### Host Firewall (Ubuntu UFW)
```bash
# Default deny incoming
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (from trusted IPs only, if possible)
sudo ufw allow from 192.168.1.0/24 to any port 22

# Allow Jenkins
sudo ufw allow from 127.0.0.1 to any port 8080

# Allow SonarQube
sudo ufw allow from 127.0.0.1 to any port 9000

# Allow Kubernetes services
sudo ufw allow from 127.0.0.1 to any port 6443  # API server

# Enable and verify
sudo ufw enable
sudo ufw status numbered
```

---

## Compliance Framework Mapping {#compliance-mapping}

### NIST SP 800-53 Controls

| Control | DevSecOps Implementation | TP Coverage |
|---------|-------------------------|------------|
| **SC-7** (Boundary Protection) | Firewall (UFW), NetworkPolicy | TP1, TP6 |
| **SI-2** (Flaw Remediation) | SAST, Dependency-Check, Trivy scans | TP2, TP3, TP4 |
| **AU-2** (Audit Events) | Auditd, Falco, Wazuh logs | TP1, TP5 |
| **AC-3** (Access Control) | RBAC, least privilege | TP1, TP6 |
| **IA-4** (Account Identification) | Service accounts, user mapping | TP6 |
| **SC-12** (Cryptography) | Secrets encryption, TLS, signing | TP3, TP6 |

### OWASP Top 10 Mapping

| OWASP Issue | Defense | TP |
|-------------|---------|-----|
| **Injection** | Input validation (app code), WAF rules | TP2, TP4 |
| **Broken Auth** | SSH hardening, RBAC, MFA setup | TP1, TP6 |
| **Sensitive Data** | Encryption, secrets management | TP1, TP3, TP6 |
| **XML External Entities** | Dependency scanning, input validation | TP2, TP4 |
| **Broken Access Control** | RBAC, NetworkPolicy, PSS | TP6 |
| **Security Misconfiguration** | OS hardening, image scanning | TP1, TP3 |
| **XSS/CSRF** | Input validation, CSP headers (app) | TP2, TP4 |
| **Insecure Deserialization** | Dependency-Check, SAST rules | TP2, TP4 |
| **Using Known Vulnerabilities** | Trivy, Dependency-Check | TP2, TP3, TP4 |
| **Insufficient Logging** | Auditd, Falco, Wazuh, centralized logging | TP1, TP5 |

### CIS Benchmark Alignment

- **CIS Ubuntu 22/24 LTS**: Achieved via TP1 hardening script (UFW, SSH, audit, disable unused services)
- **CIS Kubernetes**: Achieved via TP6 policies (RBAC, PSS, network isolation, secrets encryption)
- **CIS Docker**: Container image best practices in TP3 (scan, sign, minimal base images)

---

## Incident Response Procedures {#incident-response}

### Incident Classification

| Severity | Example | Response Time | Escalation |
|----------|---------|----------------|-----------|
| **Critical** | Active exploitation, data breach | 15 minutes | CISO, Legal |
| **High** | Unpatched critical CVE, unauthorized access | 1 hour | Security team lead |
| **Medium** | Misconfiguration, suspicious activity | 4 hours | Team lead |
| **Low** | Policy violation, informational alert | 24 hours | Security audit |

### Response Workflow

#### Step 1: Detection & Triage
```bash
# Falco alerts (runtime anomalies)
sudo docker logs falco | grep CRITICAL

# Wazuh alerts (log correlation)
curl -s http://wazuh-manager:55000/security/index

# Scan findings (vulnerabilities)
jq '.vulnerabilities[] | select(.Severity=="CRITICAL")' trivy-report/trivy-image-report.json

# Jenkins pipeline failures
curl -s http://jenkins:8080/api/json | jq '.jobs[] | select(.color | contains("red"))'
```

#### Step 2: Containment (If Needed)
```bash
# Isolate compromised pod
kubectl delete pod <compromised-pod-name>

# Cordon node (if compromise suspected)
kubectl cordon <node-name>

# Kill suspicious process
sudo pkill -f <suspicious-process>

# Revoke credentials
# Jenkins: revoke token
# Docker: revoke key
```

#### Step 3: Investigation
```bash
# Collect forensic evidence
sudo ausearch -ts recent > audit-trail.log
sudo docker logs <container-id> > container-logs.log
kubectl describe pod <pod-name> > k8s-pod-status.log
kubectl logs <pod-name> > pod-logs.log

# Analyze attack surface
trivy image <image-id> --severity HIGH,CRITICAL
gitleaks detect --source . --report-format json

# Correlate logs
grep "<artifact>" /var/log/auth.log /var/log/syslog
```

#### Step 4: Remediation
```bash
# Patch vulnerability
apt update && apt upgrade -y   # TP1 host
docker pull <image>:patched && docker tag ... # TP3 image
kubectl set image deployment/<name> <container>=<new-image>  # TP6 deployment

# Rebuild & redeploy
docker build -t <image>:v2 . && docker push ...
kubectl apply -f deployment.yaml

# Rotate credentials
# New SonarQube token
# New Docker Hub credentials
# New K8s secrets
```

#### Step 5: Post-Incident Review (Blameless)
```bash
# Document in incident log
# Timeline: What, when, who detected, impact, resolution
# Root cause: Why it happened (not who is at fault)
# Action items: How to prevent recurrence
# Follow-up: Track remediation tasks

# Schedule postmortem (24-48 hours after resolution)
# Participants: Incident commander, responders, stakeholders
# Output: Lessons learned, action items, preventive measures
```

---

## Security Audit Checklist {#audit-checklist}

### Pre-Deployment Checklist

- [ ] **Code Security**
  - [ ] No hardcoded secrets found (Gitleaks passed)
  - [ ] SAST analysis completed (SonarQube)
  - [ ] Dependencies scanned (OWASP Dependency-Check)
  - [ ] No critical/blocker issues
  - [ ] Code review completed by team lead

- [ ] **Container Security**
  - [ ] Base image from trusted registry
  - [ ] Dockerfile follows best practices (non-root user, minimal layers)
  - [ ] Image scanned with Trivy (no critical vulns)
  - [ ] Image signed with Cosign
  - [ ] No secrets in image (Gitleaks scan of Dockerfile)

- [ ] **Host Security**
  - [ ] UFW enabled
  - [ ] SSH hardened (key-only, no root)
  - [ ] Auditd running with rules
  - [ ] AIDE initialized
  - [ ] Fail2Ban active
  - [ ] Sysctl hardening applied

- [ ] **Kubernetes Security**
  - [ ] RBAC roles defined (least privilege)
  - [ ] NetworkPolicy enforced (default-deny)
  - [ ] Pod Security Standards labels applied
  - [ ] OPA Gatekeeper policies loaded (if enabled)
  - [ ] Secrets encryption configured
  - [ ] Service accounts created (no default)

- [ ] **Runtime Security**
  - [ ] Falco running with custom rules
  - [ ] Wazuh agent installed (if applicable)
  - [ ] Prometheus scraping metrics
  - [ ] Grafana dashboards configured
  - [ ] Alerting rules enabled
  - [ ] Log aggregation functional

- [ ] **Access Control**
  - [ ] Jenkins credentials stored securely
  - [ ] Docker registry credentials encrypted
  - [ ] K8s service account tokens protected
  - [ ] SSH keys backed up securely
  - [ ] MFA enabled for Jenkins (if applicable)

- [ ] **Compliance**
  - [ ] Applicable regulations identified (HIPAA, PCI-DSS, etc.)
  - [ ] Security controls map to regulations
  - [ ] Audit trail enabled (logging, monitoring)
  - [ ] Data retention policies documented
  - [ ] Privacy impact assessment completed (if needed)

### Regular Audit Schedule

| Frequency | Activity | Owner |
|-----------|----------|-------|
| **Weekly** | Review Falco/Wazuh alerts for anomalies | Ops team |
| **Weekly** | Check security scan reports (SonarQube, Trivy) | Security team |
| **Monthly** | RBAC review: validate user/group membership | Admin |
| **Monthly** | Secrets rotation: tokens, keys, passwords | Security team |
| **Quarterly** | Compliance checklist review | Security lead + Compliance |
| **Quarterly** | Penetration test or security assessment | Ext. firm / Red team |
| **Annually** | Full security audit & remediation plan | External auditor |

### Audit Evidence Collection

```bash
# Automated evidence export
mkdir -p /tmp/audit-evidence

# TP1: Host baseline
sudo bash tp1/verify_baseline.sh > /tmp/audit-evidence/tp1-baseline.txt

# TP2: Scanning results
cp gitleaks-report.json dependency-check-report/*.html /tmp/audit-evidence/

# TP3: Image scan results
cp trivy-report/*.json /tmp/audit-evidence/

# TP4: SonarQube quality gate
curl -s http://localhost:9000/api/qualitygates/show?name=... > /tmp/audit-evidence/sonar-gates.json

# TP5: Falco rules
kubectl logs -n gatekeeper-system -l app=falco | tail -100 > /tmp/audit-evidence/falco-events.log

# TP6: K8s policies
kubectl get rbac,networkpolicy,podsecurity -A -o yaml > /tmp/audit-evidence/k8s-policies.yaml

# Zip for auditor
tar -czf audit-evidence-$(date +%Y%m%d).tar.gz /tmp/audit-evidence
```

---

## Summary: Security Maturity Model

| Maturity Level | Description | TPs Required |
|---|---|---|
| **1. Initial** | Ad-hoc security, no automation | Manual checks only |
| **2. Repeatable** | Basic automation (scanning, logs) | TP1, TP2, TP3 |
| **3. Defined** | Policies, gates, monitoring | TP1-TP5 |
| **4. Managed** | Continuous improvement, metrics | TP1-TP6 + Advanced |
| **5. Optimized** | Proactive, self-healing, AI-driven | Enterprise solutions |

**Lab Achievement**: This platform achieves **Level 3–4** security maturity (Defined to Managed).

---

**Document Version**: 1.0  
**Last Updated**: November 2025
