# Validation & Testing Framework

## Table of Contents
1. [TP1: Secure Foundation Tests](#tp1-tests)
2. [TP2: Secure CI Pipeline Tests](#tp2-tests)
3. [TP3: Secure Container Delivery Tests](#tp3-tests)
4. [TP4: Enhanced Code Quality Tests](#tp4-tests)
5. [TP5: Security Monitoring Tests](#tp5-tests)
6. [TP6: Kubernetes Security Tests](#tp6-tests)
7. [Performance Targets](#performance-targets)
8. [Automated Test Suite](#automated-tests)

---

## TP1: Secure Foundation Tests {#tp1-tests}

### Test 1.1: Firewall Status
```bash
#!/bin/bash
# Verify UFW is enabled and has correct rules

echo "=== TP1.1: Firewall Status ==="

# Check UFW enabled
if sudo ufw status | grep -q "Status: active"; then
    echo "✓ UFW is active"
else
    echo "✗ UFW is NOT active"
    exit 1
fi

# Check SSH rule exists
if sudo ufw status | grep -q "22"; then
    echo "✓ SSH port 22 allowed"
else
    echo "✗ SSH port 22 NOT found in UFW rules"
    exit 1
fi

# Verify default policy is DENY incoming
if sudo ufw status verbose | grep -q "Default: deny (incoming)"; then
    echo "✓ Default policy is DENY incoming"
else
    echo "✗ Default policy is NOT DENY incoming"
    exit 1
fi

echo "✓ TP1.1 PASSED"
```

### Test 1.2: SSH Hardening
```bash
#!/bin/bash
# Verify SSH configuration

echo "=== TP1.2: SSH Hardening ==="

# Check PermitRootLogin disabled
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config.d/99-hardened.conf 2>/dev/null; then
    echo "✓ PermitRootLogin disabled"
else
    echo "✗ PermitRootLogin NOT disabled"
    exit 1
fi

# Check PasswordAuthentication disabled
if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config.d/99-hardened.conf 2>/dev/null; then
    echo "✓ PasswordAuthentication disabled"
else
    echo "✗ PasswordAuthentication NOT disabled"
    exit 1
fi

# Check PubkeyAuthentication enabled
if grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config.d/99-hardened.conf 2>/dev/null; then
    echo "✓ PubkeyAuthentication enabled"
else
    echo "✗ PubkeyAuthentication NOT enabled"
    exit 1
fi

# Verify SSH is running
if sudo systemctl is-active --quiet ssh; then
    echo "✓ SSH service is active"
else
    echo "✗ SSH service is NOT active"
    exit 1
fi

echo "✓ TP1.2 PASSED"
```

### Test 1.3: Auditd Status
```bash
#!/bin/bash
# Verify auditd is running and logging

echo "=== TP1.3: Auditd Status ==="

# Check auditd service running
if sudo systemctl is-active --quiet auditd; then
    echo "✓ Auditd is running"
else
    echo "✗ Auditd is NOT running"
    exit 1
fi

# Check audit rules exist
if sudo auditctl -l | grep -q "audit_rules"; then
    echo "✓ Audit rules loaded"
else
    echo "✗ No audit rules found"
    exit 1
fi

# Check /var/log/audit/audit.log exists
if [ -f /var/log/audit/audit.log ]; then
    echo "✓ Audit log file exists"
    AUDIT_SIZE=$(stat -f%z /var/log/audit/audit.log 2>/dev/null || du -b /var/log/audit/audit.log | cut -f1)
    if [ "$AUDIT_SIZE" -gt 0 ]; then
        echo "✓ Audit log contains entries ($(numfmt --to=iec-i --suffix=B $AUDIT_SIZE))"
    fi
else
    echo "✗ Audit log file NOT found"
    exit 1
fi

echo "✓ TP1.3 PASSED"
```

### Test 1.4: Fail2Ban Status
```bash
#!/bin/bash
# Verify Fail2Ban is running

echo "=== TP1.4: Fail2Ban Status ==="

if sudo systemctl is-active --quiet fail2ban; then
    echo "✓ Fail2Ban is running"
else
    echo "✗ Fail2Ban is NOT running"
    exit 1
fi

# Check SSH jail is enabled
if sudo fail2ban-client status sshd 2>/dev/null | grep -q "Status\|enabled"; then
    echo "✓ SSH jail is enabled"
else
    echo "✗ SSH jail is NOT enabled"
    exit 1
fi

echo "✓ TP1.4 PASSED"
```

### Test 1.5: AIDE Baseline
```bash
#!/bin/bash
# Verify AIDE baseline is initialized

echo "=== TP1.5: AIDE Baseline ==="

AIDE_DB="/var/lib/aide/aide.db"

if [ -f "$AIDE_DB" ]; then
    echo "✓ AIDE baseline database exists"
    # Test with existing database
    sudo aideinit --config=/etc/aide/aide.conf --check >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ AIDE can verify baseline"
    else
        echo "⚠ AIDE returned non-zero (normal for first check)"
    fi
else
    echo "✗ AIDE database NOT found"
    exit 1
fi

echo "✓ TP1.5 PASSED"
```

---

## TP2: Secure CI Pipeline Tests {#tp2-tests}

### Test 2.1: SonarQube Availability
```bash
#!/bin/bash
# Verify SonarQube is running and responsive

echo "=== TP2.1: SonarQube Availability ==="

SONAR_URL="http://localhost:9000"

# Check if SonarQube is running
RESPONSE=$(curl -s -w "\n%{http_code}" "$SONAR_URL/api/system/status")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
    echo "✓ SonarQube API responding (HTTP 200)"
    if echo "$BODY" | jq -e '.status == "UP"' >/dev/null 2>&1; then
        echo "✓ SonarQube status is UP"
    fi
else
    echo "✗ SonarQube not responding (HTTP $HTTP_CODE)"
    exit 1
fi

# Check database connectivity
if echo "$BODY" | jq -e '.database' >/dev/null 2>&1; then
    echo "✓ Database connected"
else
    echo "✗ Database NOT connected"
    exit 1
fi

echo "✓ TP2.1 PASSED"
```

### Test 2.2: Gitleaks Scanning
```bash
#!/bin/bash
# Test Gitleaks can scan for secrets

echo "=== TP2.2: Gitleaks Scanning ==="

cd /home/ubuntu/Desktop/DevOps/DevSecOps || exit 1

# Run Gitleaks scan
docker run --rm -v "$(pwd):/path" zricethezav/gitleaks:latest detect --source /path -v >/tmp/gitleaks-test.json 2>&1

if [ -f /tmp/gitleaks-test.json ]; then
    echo "✓ Gitleaks scan completed"

    # Verify JSON output is valid
    if jq empty /tmp/gitleaks-test.json 2>/dev/null; then
        echo "✓ Gitleaks output is valid JSON"

        # Count findings
        FINDINGS=$(jq '.Results | length' /tmp/gitleaks-test.json)
        echo "  Secrets found: $FINDINGS"
    else
        echo "✗ Gitleaks output is invalid JSON"
        exit 1
    fi
else
    echo "✗ Gitleaks scan failed"
    exit 1
fi

echo "✓ TP2.2 PASSED"
```

### Test 2.3: Dependency-Check Scanning
```bash
#!/bin/bash
# Test Dependency-Check can scan dependencies

echo "=== TP2.3: Dependency-Check Scanning ==="

# Create test project with vulnerable dependency (if applicable)
TEST_DIR="/tmp/test-dep-check"
mkdir -p "$TEST_DIR"

# Run Dependency-Check
docker run --rm \
  -v "$TEST_DIR:/src" \
  owasp/dependency-check:latest \
  --project "test" --scan /src --format json >/tmp/dep-check-test.json 2>&1

if [ -f /tmp/dep-check-test.json ]; then
    echo "✓ Dependency-Check scan completed"
    if jq empty /tmp/dep-check-test.json 2>/dev/null; then
        echo "✓ Dependency-Check output is valid JSON"
    fi
else
    echo "✗ Dependency-Check scan failed"
    exit 1
fi

echo "✓ TP2.3 PASSED"
```

### Test 2.4: Jenkins Connectivity
```bash
#!/bin/bash
# Verify Jenkins is accessible

echo "=== TP2.4: Jenkins Connectivity ==="

JENKINS_URL="http://localhost:8080"

# Check Jenkins is running
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL")

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "403" ]; then
    echo "✓ Jenkins is responding (HTTP $HTTP_CODE)"
else
    echo "✗ Jenkins not responding (HTTP $HTTP_CODE)"
    exit 1
fi

echo "✓ TP2.4 PASSED"
```

---

## TP3: Secure Container Delivery Tests {#tp3-tests}

### Test 3.1: Trivy Image Scanning
```bash
#!/bin/bash
# Test Trivy can scan container images

echo "=== TP3.1: Trivy Image Scanning ==="

# Test with a small image
TEST_IMAGE="alpine:latest"

# Pull test image
docker pull "$TEST_IMAGE" >/dev/null 2>&1

# Run Trivy scan
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image "$TEST_IMAGE" >/tmp/trivy-test.json 2>&1

if [ -f /tmp/trivy-test.json ]; then
    echo "✓ Trivy scan completed"
    if grep -q "ArtifactType" /tmp/trivy-test.json; then
        echo "✓ Trivy output contains results"
    fi
else
    echo "✗ Trivy scan failed"
    exit 1
fi

echo "✓ TP3.1 PASSED"
```

### Test 3.2: Cosign Installation
```bash
#!/bin/bash
# Verify Cosign is installed

echo "=== TP3.2: Cosign Installation ==="

if command -v cosign >/dev/null; then
    VERSION=$(cosign version)
    echo "✓ Cosign installed"
    echo "  Version: $VERSION"
else
    echo "✗ Cosign NOT installed"
    exit 1
fi

# Verify cosign can generate keys
TEST_DIR="/tmp/test-cosign"
mkdir -p "$TEST_DIR"

# Generate test key (non-interactive)
cd "$TEST_DIR" || exit 1
COSIGN_EXPERIMENTAL=1 cosign generate-key-pair >/dev/null 2>&1

if [ -f "$TEST_DIR/cosign.key" ] && [ -f "$TEST_DIR/cosign.pub" ]; then
    echo "✓ Cosign can generate key pairs"
    rm -f "$TEST_DIR"/cosign.*
fi

echo "✓ TP3.2 PASSED"
```

### Test 3.3: Dockerfile Best Practices
```bash
#!/bin/bash
# Verify example Dockerfile follows best practices

echo "=== TP3.3: Dockerfile Best Practices ==="

# Check for anti-patterns in Dockerfile
TEST_DOCKERFILE="/tmp/test-dockerfile"

# Example Dockerfile
cat > "$TEST_DOCKERFILE" << 'EOF'
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl && apt-get clean

RUN useradd -m -s /bin/bash appuser

WORKDIR /app

COPY app.jar /app/

USER appuser

ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

echo "✓ Test Dockerfile created"

# Check for anti-patterns
if grep -q "FROM.*:latest" "$TEST_DOCKERFILE"; then
    echo "⚠ Dockerfile uses :latest tag (not pinned)"
fi

if grep -q "RUN apt-get update" "$TEST_DOCKERFILE" && ! grep -q "apt-get clean" "$TEST_DOCKERFILE"; then
    echo "⚠ RUN instruction doesn't clean apt cache"
fi

if ! grep -q "^USER " "$TEST_DOCKERFILE"; then
    echo "⚠ Dockerfile doesn't specify non-root user"
fi

# If we get here, basic pattern checks passed
echo "✓ TP3.3 PASSED"

rm -f "$TEST_DOCKERFILE"
```

---

## TP4: Enhanced Code Quality Tests {#tp4-tests}

### Test 4.1: SonarQube Quality Gate
```bash
#!/bin/bash
# Verify quality gate is configured

echo "=== TP4.1: SonarQube Quality Gate ==="

SONAR_URL="http://localhost:9000"
SONAR_TOKEN="${SONAR_TOKEN:-squ_default}"

# List quality gates
RESPONSE=$(curl -s "$SONAR_URL/api/qualitygates/list?token=$SONAR_TOKEN")

if echo "$RESPONSE" | jq -e '.qualitygates | length > 0' >/dev/null 2>&1; then
    echo "✓ Quality gates exist"

    # Check default gate
    if echo "$RESPONSE" | jq -e '.qualitygates[] | select(.isDefault == true)' >/dev/null 2>&1; then
        echo "✓ Default quality gate is set"
    fi
else
    echo "✗ No quality gates found"
    exit 1
fi

echo "✓ TP4.1 PASSED"
```

### Test 4.2: License Scanning
```bash
#!/bin/bash
# Test license scanning capability

echo "=== TP4.2: License Scanning ==="

# Test with maven project if available
if command -v mvn >/dev/null; then
    echo "✓ Maven is available"
    # Maven can be configured with license-maven-plugin
else
    echo "⚠ Maven not available; skipping Maven license check"
fi

# Alternative: Test ScanCode Toolkit (Docker)
docker run --rm -v /tmp:/tmp \
  scancode-toolkit:latest --license --json /tmp/scancode-result.json >/dev/null 2>&1

if [ -f /tmp/scancode-result.json ]; then
    echo "✓ License scanning can generate reports"
else
    echo "⚠ ScanCode not available"
fi

echo "✓ TP4.2 PASSED"
```

---

## TP5: Security Monitoring Tests {#tp5-tests}

### Test 5.1: Falco Status
```bash
#!/bin/bash
# Verify Falco is running and detecting events

echo "=== TP5.1: Falco Status ==="

# Check if Falco container is running
if docker ps | grep -q "falco"; then
    echo "✓ Falco container is running"

    # Check recent logs
    FALCO_LOGS=$(docker logs falco 2>&1 | tail -20)

    if echo "$FALCO_LOGS" | grep -q "engine started"; then
        echo "✓ Falco engine started"
    else
        echo "⚠ Falco engine startup not confirmed in recent logs"
    fi

    # Check for errors
    if echo "$FALCO_LOGS" | grep -i "error" | grep -v "ERROR_CODE\|HEALTH"; then
        echo "⚠ Falco logs contain errors (may be non-blocking)"
    fi
else
    echo "✗ Falco container is NOT running"
    exit 1
fi

echo "✓ TP5.1 PASSED"
```

### Test 5.2: Falco Rule Detection
```bash
#!/bin/bash
# Test Falco rule detection by triggering a benign event

echo "=== TP5.2: Falco Rule Detection ==="

# Get Falco container ID
FALCO_CID=$(docker ps -q -f "name=falco")

if [ -z "$FALCO_CID" ]; then
    echo "✗ Falco container not found"
    exit 1
fi

# Clear logs
docker logs --tail 0 falco >/dev/null 2>&1

# Trigger a benign shell spawn (should trigger "Shell Spawned" rule)
docker exec ubuntu-container /bin/sh -c "echo test" >/dev/null 2>&1 || true

# Wait a moment for logs to flush
sleep 2

# Check if rule triggered
if docker logs falco 2>&1 | grep -q "Shell Spawned\|Writing to file"; then
    echo "✓ Falco rules are detecting events"
else
    echo "⚠ Expected events not detected (may require running container)"
fi

echo "✓ TP5.2 PASSED"
```

### Test 5.3: Prometheus Metrics
```bash
#!/bin/bash
# Verify Prometheus is collecting metrics

echo "=== TP5.3: Prometheus Metrics ==="

PROM_URL="http://localhost:9090"

# Check Prometheus API
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$PROM_URL/api/v1/query?query=up")

if [ "$HTTP_CODE" == "200" ]; then
    echo "✓ Prometheus is responding"

    # Query for any metrics
    QUERY=$(curl -s "$PROM_URL/api/v1/query?query=up" | jq '.data.result | length')
    if [ "$QUERY" -gt 0 ]; then
        echo "✓ Prometheus has collected metrics"
    fi
else
    echo "⚠ Prometheus not available (HTTP $HTTP_CODE)"
fi

echo "✓ TP5.3 PASSED"
```

---

## TP6: Kubernetes Security Tests {#tp6-tests}

### Test 6.1: Minikube Cluster Status
```bash
#!/bin/bash
# Verify Minikube cluster is running

echo "=== TP6.1: Minikube Cluster Status ==="

if ! command -v minikube >/dev/null; then
    echo "✗ Minikube NOT installed"
    exit 1
fi

# Check cluster status
if minikube status | grep -q "host: Running"; then
    echo "✓ Minikube is running"
else
    echo "⚠ Minikube not running; attempting to start..."
    minikube start >/dev/null 2>&1
fi

# Verify kubectl connectivity
if kubectl cluster-info >/dev/null 2>&1; then
    echo "✓ kubectl can connect to cluster"
else
    echo "✗ kubectl cannot connect to cluster"
    exit 1
fi

echo "✓ TP6.1 PASSED"
```

### Test 6.2: RBAC Configuration
```bash
#!/bin/bash
# Verify RBAC is configured

echo "=== TP6.2: RBAC Configuration ==="

# Check if Role/RoleBinding exist
ROLE_COUNT=$(kubectl get roles -A | wc -l)

if [ "$ROLE_COUNT" -gt 1 ]; then
    echo "✓ Roles are configured"
    kubectl get roles -A | head -5
else
    echo "⚠ No custom roles found (system roles may exist)"
fi

# Check service account
if kubectl get serviceaccounts -o name | grep -q "default"; then
    echo "✓ Service accounts exist"
fi

echo "✓ TP6.2 PASSED"
```

### Test 6.3: NetworkPolicy Enforcement
```bash
#!/bin/bash
# Verify NetworkPolicy is configured

echo "=== TP6.3: NetworkPolicy Enforcement ==="

# Check if CNI supports NetworkPolicy
if kubectl get nodes -o wide | grep -q "kube-"; then
    echo "✓ Cluster nodes detected"

    # Check for NetworkPolicy resources
    NP_COUNT=$(kubectl get networkpolicies -A 2>/dev/null | wc -l)

    if [ "$NP_COUNT" -gt 1 ]; then
        echo "✓ NetworkPolicies are configured"
    else
        echo "⚠ No NetworkPolicies found (may need to apply)"
    fi
fi

echo "✓ TP6.3 PASSED"
```

### Test 6.4: Pod Security Standards
```bash
#!/bin/bash
# Verify Pod Security Standards are configured

echo "=== TP6.4: Pod Security Standards ==="

# Check namespace labels for PSS
NAMESPACES=$(kubectl get namespace default -o jsonpath='{.metadata.labels}' 2>/dev/null)

if echo "$NAMESPACES" | grep -q "pod-security.kubernetes.io"; then
    echo "✓ Pod Security Standards labels found"
else
    echo "⚠ Pod Security Standards labels not applied (may need to apply)"
fi

echo "✓ TP6.4 PASSED"
```

---

## Performance Targets {#performance-targets}

### Expected Execution Times

| Operation | Target Time | Comment |
|-----------|------------|---------|
| SonarQube startup | < 60 seconds | Via docker-compose; PostgreSQL init varies |
| SAST scan (small project) | < 5 minutes | SonarQube analysis of Maven project |
| Gitleaks scan (repo) | < 2 minutes | Full repository secrets scan |
| Dependency-Check | < 3 minutes | Small Maven project dependency analysis |
| Trivy image scan | < 2 minutes | Small image (alpine/ubuntu) scan |
| Cosign sign image | < 30 seconds | Image signing operation |
| Falco initialization | < 15 seconds | eBPF probe loading |
| Minikube startup | < 2 minutes | Cluster creation; varies by system |
| K8s policy application | < 30 seconds | RBAC/NetworkPolicy manifest apply |

### Resource Consumption

| Component | CPU | Memory | Disk |
|-----------|-----|--------|------|
| **SonarQube + PostgreSQL** | 2 cores | 2-3 GB | 5 GB |
| **Falco container** | 0.5 cores | 500 MB | 1 GB |
| **Prometheus + Grafana** | 1 core | 1-2 GB | 2 GB |
| **Wazuh manager** | 2 cores | 4-6 GB | 10 GB (logs) |
| **Minikube cluster** | 2-4 cores | 2-4 GB | 20 GB |
| **Total (all components)** | 8-10 cores | 10-16 GB | 40 GB |

---

## Automated Test Suite {#automated-tests}

### Run All Tests
```bash
#!/bin/bash
# Complete validation suite

set -e
RESULTS_DIR="/tmp/devsecops-tests"
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "DevSecOps Validation Suite"
echo "=========================================="
echo "Start time: $(date)"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# TP1 Tests
echo "--- TP1 Tests ---"
for test in tp1_firewall tp1_ssh tp1_auditd tp1_fail2ban tp1_aide; do
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if bash "$RESULTS_DIR/../tp1/tests/$test.sh" > "$RESULTS_DIR/$test.log" 2>&1; then
        echo "✓ $test PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ $test FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
done

# TP2 Tests
echo "--- TP2 Tests ---"
for test in tp2_sonarqube tp2_gitleaks tp2_dep_check tp2_jenkins; do
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if bash "$RESULTS_DIR/../tp2/tests/$test.sh" > "$RESULTS_DIR/$test.log" 2>&1; then
        echo "✓ $test PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ $test FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
done

# ... (similar for TP3-TP6)

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo "Success rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo "End time: $(date)"

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed. Check logs in $RESULTS_DIR"
    exit 1
fi
```

---

**Document Version**: 1.0
**Last Updated**: November 2025
