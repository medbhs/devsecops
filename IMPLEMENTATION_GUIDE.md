# DevSecOps Transformation: Complete Step-by-Step Implementation Guide

## Table of Contents
1. [Prerequisites & Environment Setup](#prerequisites)
2. [TP1: Secure Foundation (Ubuntu 24.04 Hardening)](#tp1-implementation)
3. [TP2: Secure CI Pipeline (Jenkins + SAST)](#tp2-implementation)
4. [TP3: Secure Container Delivery (Docker + Trivy + Cosign)](#tp3-implementation)
5. [TP4: Enhanced Code Quality (SonarQube + Gates)](#tp4-implementation)
6. [TP5: Security Monitoring (Falco + Wazuh + Prometheus/Grafana)](#tp5-implementation)
7. [TP6: Kubernetes Security (Minikube + RBAC + OPA)](#tp6-implementation)
8. [Validation & Testing](#validation)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites & Environment Setup {#prerequisites}

### System Requirements
- **OS**: Ubuntu 24.04 LTS (Noble)
- **Hardware**: Minimum 8GB RAM, 6+ CPU cores, 100GB disk (Dell G15 laptop suitable)
- **Internet**: Required for package downloads and container images
- **User**: sudoer access needed for many commands

### Initial Environment Check
```bash
# Verify system
uname -a
lsb_release -a

# Check disk space
df -h /

# Check memory
free -h

# Install base tools if missing
sudo apt update
sudo apt install -y curl wget git build-essential jq vim
```

### Clone or Extract Lab Repository
```bash
cd /home/ubuntu/Desktop/DevOps/DevSecOps
ls -la tp1 tp2 tp3 tp4 tp5 tp6  # Verify all TP directories present
```

---

## TP1: Secure Foundation (Ubuntu 24.04 Hardening) {#tp1-implementation}

### Step 1: Review Security Gaps
```bash
cat tp1/README_TP1.md
```

### Step 2: Prepare Hardening Script
```bash
cd tp1
chmod +x harden_ubuntu24.sh verify_baseline.sh

# Review script before execution
head -50 harden_ubuntu24.sh
```

### Step 3: Execute Hardening (Requires Sudo)
```bash
# WARNING: This makes system-level changes (SSH config, firewall, audit)
# Run on a test VM first if unsure

sudo bash ./harden_ubuntu24.sh

# Expected output: UFW enabled, SSH hardening written, auditd/AIDE/Fail2Ban configured
```

### Step 4: Verify Baseline Security
```bash
sudo bash ./verify_baseline.sh

# Expected output examples:
# - "UFW status: active, incoming: deny, outgoing: allow"
# - "auditd active"
# - "fail2ban active"
# - "AIDE DB present"
```

### Step 5: Configure SSH Key-Based Access (Post-Hardening)
```bash
# If SSH disallowed password auth and you don't have key-based login:
# Use console/physical access to fix, OR set SSH_DROPIN properly before running script

# For lab environment, ensure you have SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/id_lab -N ""

# Add to authorized_keys on the hardened host
cat ~/.ssh/id_lab.pub | sudo tee -a ~/.ssh/authorized_keys
```

### TP1 Success Criteria
- ✓ UFW status shows "active"
- ✓ SSH permits only key-based auth
- ✓ auditd, AIDE, Fail2Ban running
- ✓ Sysctl hardening applied
- ✓ Audit rules loaded

---

## TP2: Secure CI Pipeline (Jenkins + SAST) {#tp2-implementation}

### Step 1: Install Tools & Pull Scanner Images
```bash
cd tp2
chmod +x install_tools.sh *.sh verify_tp2.sh

# Check Docker already installed
docker --version

# Pull scanner images
sudo bash ./install_tools.sh
# Expected: sonar-scanner-cli, owasp/dependency-check, gitleaks images pulled
```

### Step 2: Start SonarQube (Docker Compose)
```bash
# Navigate to tp2
cd tp2

# Start SonarQube + PostgreSQL
docker-compose -f sonarqube-docker-compose.yml up -d

# Wait 1-2 minutes for SonarQube to start
sleep 120

# Verify SonarQube is running
curl -s http://localhost:9000/api/system/status | jq .
# Expected: {"status":"UP"}

# Access web UI: http://localhost:9000
# Default login: admin / admin (change password on first login!)
```

### Step 3: Generate SonarQube Token
```bash
# In SonarQube UI (http://localhost:9000):
# 1. Login as admin
# 2. Go to User → My Account → Security → Generate token
# 3. Save token (e.g., squ_abc123def456...)

# Store token in environment for later use
export SONAR_TOKEN="squ_abc123def456..."
export SONAR_HOST_URL="http://localhost:9000"
```

### Step 4: Install Jenkins & Configure Credentials
```bash
# Jenkins may already be installed (from earlier setup)
sudo systemctl status jenkins

# If not installed:
# (Refer to tool installation output earlier)

# Access Jenkins: http://localhost:8080
# First-time setup: retrieve initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Jenkins → Manage → Manage Credentials → Add Credentials
# Create:
# 1. Secret text: ID="sonar-token", secret=<your_token>
# 2. Username/Password: ID="dockerhub", for Docker Hub login
# 3. Secret text: ID="sonar-host-url", secret="http://localhost:9000"
```

### Step 5: Create Jenkins Job / Pipeline
```bash
# Option A: Use the provided Jenkinsfile from root
cd /home/ubuntu/Desktop/DevOps/DevSecOps
cat Jenkinsfile  # Review full pipeline

# Option B: Create a new Freestyle or Pipeline job in Jenkins UI
# Use SCM: Git repo URL
# Pipeline script: Paste content from Jenkinsfile

# Test trigger:
# Commit code change or manually trigger build
```

### Step 6: Run Test Scans
```bash
cd tp2

# Test Gitleaks (scan current repo for secrets)
bash gitleaks_scan.sh /home/ubuntu/Desktop/DevOps/DevSecOps

# Test SonarQube Scanner
export SONAR_LOGIN="$SONAR_TOKEN"
export SONAR_HOST_URL="http://localhost:9000"
bash sonar_scan.sh /home/ubuntu/Desktop/DevOps/DevSecOps

# Test Dependency-Check
bash dependency_check_scan.sh /home/ubuntu/Desktop/DevOps/DevSecOps

# Verify reports generated
ls -lh gitleaks-report.json dependency-check-report/
```

### TP2 Success Criteria
- ✓ SonarQube running and accessible
- ✓ Scanner images pulled successfully
- ✓ Jenkins configured with credentials
- ✓ Test scans complete without errors
- ✓ Reports generated in expected locations

---

## TP3: Secure Container Delivery (Docker + Trivy + Cosign) {#tp3-implementation}

### Step 1: Install Trivy & Cosign
```bash
cd tp3
chmod +x *.sh

# Install Cosign (binary)
sudo bash cosign_install.sh
cosign version

# Install Trivy (or use Docker image)
sudo apt install -y trivy
trivy version
```

### Step 2: Prepare Dockerfile (or Use Existing)
```bash
# If no Dockerfile present, create a simple one for testing:
cat > Dockerfile <<'EOF'
FROM ubuntu:24.04
RUN apt update && apt install -y curl && apt-get clean
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["bash"]
EOF
```

### Step 3: Build Docker Image
```bash
docker build -t lab-app:v1.0 .
docker images | grep lab-app
```

### Step 4: Scan Image with Trivy
```bash
cd tp3
bash trivy_scan.sh image lab-app:v1.0

# Review report
cat trivy-report/trivy-image-report.json | jq '.Results[] | select(.Vulnerabilities != null)'
```

### Step 5: Generate & Setup Cosign Keys
```bash
cd tp3

# Generate key pair (protect with password)
export COSIGN_PASSWORD="secure_lab_password"
bash cosign_sign_image.sh lab-app:v1.0

# Verify key files created
ls -l ~/.cosign/
```

### Step 6: Push Image & Sign (Docker Hub or Local Registry)
```bash
# Tag for Docker Hub
docker tag lab-app:v1.0 <your-dockerhub-user>/lab-app:v1.0

# Push (requires login)
docker login
docker push <your-dockerhub-user>/lab-app:v1.0

# Or use local registry (Harbor/simple registry)
```

### TP3 Success Criteria
- ✓ Trivy installed and scanning images
- ✓ Cosign keys generated
- ✓ Image vulnerability reports generated
- ✓ Image signed successfully
- ✓ Dockerfile follows best practices

---

## TP4: Enhanced Code Quality (SonarQube + Gates) {#tp4-implementation}

### Step 1: Configure SonarQube Quality Gate
```bash
cd tp4

# Create quality gate via API (requires SONAR_TOKEN)
export SONAR_HOST_URL="http://localhost:9000"
export SONAR_TOKEN="squ_..."

# Review example gate definition
cat sonar_quality_gate.json

# Optionally import via API (advanced)
# curl -u $SONAR_TOKEN: -X POST $SONAR_HOST_URL/api/qualitygates/create ...
```

### Step 2: Enable Security Rules in SonarQube
```bash
# In SonarQube UI (http://localhost:9000):
# 1. Go to Quality Profiles
# 2. Select Language (e.g., Java)
# 3. Search for "security" rules
# 4. Enable recommended security rules (OWASP, CWE)
# 5. Activate on your project profile
```

### Step 3: Integrate Dependency-Check Reports
```bash
cd tp4

# Review integration helper
cat integrate_dependency_check.sh

# Dependency-Check reports are generated in TP2
# SonarQube can ingest via Dependency-Check plugin (if installed)
```

### Step 4: License Scanning (Optional)
```bash
# Use ScanCode for license detection
docker pull nexB/scancode-toolkit

cd /home/ubuntu/Desktop/DevOps/DevSecOps
docker run --rm -v $PWD:/src:ro nexB/scancode-toolkit:latest \
  scancode --format json --output /src/scancode-report.json /src

# Review licenses found
jq '.files[] | select(.licenses | length > 0) | .path,.licenses[].key' scancode-report.json
```

### TP4 Success Criteria
- ✓ Quality gate defined in SonarQube
- ✓ Security rules enabled (OWASP/CWE)
- ✓ Dependency-Check reports linked
- ✓ License scanning operational
- ✓ Build gates enforced in pipeline

---

## TP5: Security Monitoring (Falco + Wazuh + Prometheus/Grafana) {#tp5-implementation}

### Step 1: Install & Start Falco
```bash
cd tp5
chmod +x *.sh

# Install Falco (may fall back to Docker)
sudo bash install_falco.sh

# Verify Falco running
docker ps --filter "name=falco"
# or
systemctl status falco

# Check Falco logs
sudo docker logs falco --tail 50
# or
sudo journalctl -u falco -n 50
```

### Step 2: Copy Custom Falco Rules
```bash
cd tp5
sudo cp falco_rules.custom.yaml /etc/falco/falco_rules.local.yaml
sudo docker restart falco
sleep 3
sudo docker logs falco | tail -30
```

### Step 3: Run Falcosidekick (Forward Events to Prometheus)
```bash
# Option A: Docker run (simplest for lab)
docker run -d --name falcosidekick \
  -p 2801:2801 \
  falcosecurity/falcosidekick:latest \
  -outputprometheus=true \
  -outputprometheuslistenaddress=0.0.0.0:2801

# Verify metrics endpoint
curl -s http://localhost:2801/metrics | head -10
```

### Step 4: Install Prometheus & Grafana (Optional but Recommended)
```bash
# Prometheus - collect metrics from Falcosidekick
docker run -d --name prometheus \
  -p 9090:9090 \
  -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest

# Add Falcosidekick scrape config to /tmp/prometheus.yml:
cat >> /tmp/prometheus.yml <<EOF
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'falcosidekick'
    static_configs:
      - targets: ['localhost:2801']
EOF

# Grafana - visualization
docker run -d --name grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:latest

# Access Grafana: http://localhost:3000 (admin/admin)
```

### Step 5: Create Security Dashboards in Grafana
```bash
# In Grafana UI:
# 1. Add data source: Prometheus http://localhost:9090
# 2. Create dashboard with panels showing:
#    - Falco alert count by severity
#    - Anomalous process executions
#    - File access patterns
# 3. Import provided grafana_security_dashboard.json
```

### TP5 Success Criteria
- ✓ Falco container running and detecting events
- ✓ Falcosidekick forwarding events to Prometheus
- ✓ Prometheus scraping metrics
- ✓ Grafana dashboards displaying security metrics
- ✓ Alerts configured for anomalies

---

## TP6: Kubernetes Security (Minikube + RBAC + OPA) {#tp6-implementation}

### Step 1: Start Minikube Cluster
```bash
minikube start --cpus=4 --memory=4096 --disk-size=20g

# Verify cluster
kubectl cluster-info
kubectl get nodes

# Configure kubectl
export KUBECONFIG=$(minikube config get profile)
```

### Step 2: Enable Network Policy Support (Calico CNI)
```bash
minikube addons enable cni
minikube addons enable calico

# Wait for Calico pods to be ready
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s
```

### Step 3: Apply RBAC Policies
```bash
cd tp6
kubectl apply -f rbac_restrict.yaml

# Verify RBAC
kubectl get roles,rolebindings -n default
```

### Step 4: Apply NetworkPolicies
```bash
cd tp6
kubectl apply -f networkpolicy_default_deny.yaml

# Verify policies
kubectl get networkpolicy -A
```

### Step 5: Apply Pod Security Standards (PSS)
```bash
cd tp6
kubectl apply -f podsecurity_restrictive.yaml

# Verify namespaces
kubectl get ns --show-labels
```

### Step 6: Install OPA Gatekeeper (Optional but Powerful)
```bash
# Add Gatekeeper helm repo
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update

# Install Gatekeeper
helm install gatekeeper/gatekeeper --namespace gatekeeper-system --create-namespace

# Wait for Gatekeeper pods
kubectl wait --for=condition=ready pod -l gatekeeper.sh/system=yes -n gatekeeper-system --timeout=300s

# Apply ConstraintTemplate & Constraint
cd tp6
kubectl apply -f gatekeeper_constraint_template_image_vuln.yaml
kubectl apply -f gatekeeper_constraint_image_vuln.yaml

# Test: Try to create deployment with :latest tag (should be blocked)
kubectl run test-latest --image=nginx:latest
# Expected: Error from server (Forbidden): admission webhook denied...
```

### Step 7: Deploy Application to K8s
```bash
# Create a simple deployment manifest:
cat > k8s-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lab-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lab-app
  template:
    metadata:
      labels:
        app: lab-app
    spec:
      serviceAccountName: default
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: app
        image: ubuntu:24.04
        command: ["/bin/sleep", "3600"]
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

kubectl apply -f k8s-deployment.yaml

# Verify deployment
kubectl get deployments,pods
```

### TP6 Success Criteria
- ✓ Minikube cluster running
- ✓ RBAC roles/bindings applied
- ✓ NetworkPolicies active (default-deny + allow rules)
- ✓ Pod Security Standards enforced
- ✓ OPA Gatekeeper blocking non-compliant images (if installed)
- ✓ Application deployed with security context

---

## Validation & Testing {#validation}

### Comprehensive Validation Script
```bash
#!/bin/bash
# Run all verification scripts
set -e

echo "=== TP1 BASELINE CHECK ==="
sudo bash tp1/verify_baseline.sh

echo -e "\n=== TP2 SCANNER VERIFICATION ==="
bash tp2/verify_tp2.sh

echo -e "\n=== TP3 CONTAINER TOOLS CHECK ==="
trivy version && echo "✓ Trivy OK" || echo "✗ Trivy missing"
cosign version && echo "✓ Cosign OK" || echo "✗ Cosign missing"

echo -e "\n=== TP5 RUNTIME SECURITY CHECK ==="
bash tp5/verify_tp5.sh

echo -e "\n=== TP6 KUBERNETES CHECK ==="
if command -v kubectl >/dev/null 2>&1; then
  bash tp6/verify_tp6.sh
else
  echo "kubectl not found; K8s check skipped"
fi

echo -e "\n=== FINAL SUMMARY ==="
echo "All validations completed. Review results above for failures."
```

### Performance Targets
- Secret scanning: < 1 minute
- SAST (SonarQube): < 5 minutes
- Dependency-Check: < 2 minutes
- Container scan (Trivy): < 2 minutes
- K8s policy check: < 30 seconds

### Test Cases

#### TP1: Firewall & SSH
```bash
# Verify SSH denies password auth
ssh -o PreferredAuthentications=password user@host  # Should FAIL

# Verify firewall blocks unwanted ports
nmap localhost | grep 9999  # Should be filtered

# Verify audit logs
sudo ausearch -k identity | head -5
```

#### TP2: Secret Detection
```bash
# Create file with fake AWS key
echo "aws_secret_access_key=AKIAIOSFODNN7EXAMPLE" > test_secret.txt
cd tp2 && bash gitleaks_scan.sh /path/to/test_secret.txt
# Should detect secret

rm test_secret.txt
```

#### TP3: Image Scanning
```bash
# Build image with known vulnerability
docker build -t vuln-app:v1 - <<'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y libssl1.1
EOF

bash tp3/trivy_scan.sh image vuln-app:v1
# Should detect CVEs
```

#### TP6: Admission Control
```bash
# Try to deploy image from :latest (should fail if Gatekeeper enabled)
kubectl run test-fail --image=ubuntu:latest --namespace default
# Expected: Forbidden

# Deploy with pinned image (should succeed)
kubectl run test-pass --image=ubuntu:24.04 --namespace default
```

---

## Troubleshooting {#troubleshooting}

### Common Issues & Fixes

#### SonarQube Won't Start
```bash
# Check PostgreSQL logs
docker-compose -f tp2/sonarqube-docker-compose.yml logs db

# Increase wait time or memory
docker-compose -f tp2/sonarqube-docker-compose.yml logs sonarqube | tail -50

# Reset (careful - loses data)
docker-compose -f tp2/sonarqube-docker-compose.yml down -v
docker-compose -f tp2/sonarqube-docker-compose.yml up -d
```

#### Gitleaks Reports No Files
```bash
# Gitleaks scans git history, not filesystem
# Ensure you're in a git repo
cd /path/to/git/repo
git status  # Should show output

# Or disable history scan (scan only uncommitted)
docker run -v $PWD:/src -w /src zricethezav/gitleaks:latest \
  detect --source . --no-git --verbose
```

#### Falco Rules Won't Load
```bash
# Check Falco logs
sudo docker logs falco | grep -i "error\|invalid"

# Validate rule syntax
docker run --rm -v /etc/falco:/etc/falco \
  falcosecurity/falco:latest -o rule_file=/etc/falco/falco_rules.local.yaml -c /etc/falco/falco.yaml

# Simplify rules and remove complex output tokens
```

#### Minikube Won't Start
```bash
# Check system resources
free -h
df -h

# Reset minikube
minikube delete
minikube start --memory=4096 --cpus=4

# Check Docker daemon
systemctl status docker
sudo systemctl restart docker
```

#### Jenkins Can't Find docker/kubectl
```bash
# Jenkins runs as jenkins user; ensure permissions
sudo usermod -aG docker jenkins
sudo usermod -aG sudo jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Check $PATH for jenkins user
sudo -u jenkins echo $PATH
```

### Debug Mode for Pipelines
```bash
# Enable Jenkins Pipeline debug
# In Jenkinsfile, add: set -x

# Or run manual debug
bash -x tp1/harden_ubuntu24.sh 2>&1 | tee debug.log
```

### Collecting Logs for Support
```bash
# Gather diagnostics
mkdir -p /tmp/devsecops-logs
sudo journalctl -u auditd > /tmp/devsecops-logs/auditd.log
docker logs falco > /tmp/devsecops-logs/falco.log
kubectl describe nodes > /tmp/devsecops-logs/k8s-nodes.log
tar -czf devsecops-logs.tar.gz /tmp/devsecops-logs/
```

---

## Next Steps & Advanced Topics

### Production Hardening
- Move Wazuh to separate infrastructure
- Use managed Kubernetes (EKS, GKE)
- Integrate with enterprise SIEM/Log management
- Implement CI/CD pipeline with GitOps (ArgoCD)

### Compliance & Audit
- Map controls to regulatory requirements (HIPAA, PCI-DSS, GDPR, SOC 2)
- Implement automated compliance reporting
- Schedule regular penetration tests

### Security Operations (SecOps)
- Develop incident response playbooks
- Integrate with ticketing systems (Jira, Splunk)
- Automate response actions (remediation)
- Conduct security training & drills

---

**Document Version**: 1.0
**Last Updated**: November 2025
**Environment**: Ubuntu 24.04 LTS, Local Lab
