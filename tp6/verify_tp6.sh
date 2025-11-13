#!/usr/bin/env bash
# Verify TP6 policies in Minikube
set -euo pipefail

echo "[+] Checking namespaces and PodSecurity labels"
kubectl get ns --show-labels

echo "[+] Checking NetworkPolicy"
kubectl get networkpolicy -A || true

echo "[+] Checking Gatekeeper deployment"
kubectl get pods -n gatekeeper-system || echo "Gatekeeper not installed"

echo "[+] Trying to create deployment with :latest image (should be blocked if Gatekeeper active)"
cat <<EOF | kubectl apply -f - || true
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-latest
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-latest
  template:
    metadata:
      labels:
        app: test-latest
    spec:
      containers:
      - name: test
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

echo "[+] verify complete (if Gatekeeper installed, the test deployment should be denied)"
