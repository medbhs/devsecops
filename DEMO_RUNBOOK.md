10-minute DevSecOps Demo Runbook
================================

This runbook contains a compact script and copy/paste commands to present the platform built from TP1–TP6. It also lists safe verification commands you can run to show evidence quickly.

Quick facts
-----------
- Host: Ubuntu 24.04 (demo machine)
- Grafana: http://localhost:3000  (admin / 1234)
- Prometheus: http://localhost:9090
- Minikube kubectl context: minikube

Files of interest (in repo)
---------------------------
- `tp1/aide-check.txt` — AIDE filesystem integrity check
- `tp3/trivy-report.json` — Trivy image scan report
- `tp5/falco-detection.log` — Falco detection log
- `tp5/grafana_security_dashboard.json` — Grafana dashboard JSON (imported)
- `tp6/gatekeeper-test.txt` — Gatekeeper denial evidence
- `artifacts/` — All generated reports and evidence

Two-minute overview (what to say)
---------------------------------
1. Defense-in-depth: shift-left scanning (Trivy/Gitleaks/Dependency-Check), image signing (Cosign), admission controls (Gatekeeper), runtime detection (Falco), and observability (Prometheus/Grafana).
2. Flow: scan -> sign -> gate -> run -> detect -> visualize.
3. Evidence: all reports saved to `artifacts/` and `tp*/` directories.

Live demo steps and commands
----------------------------
(Use this order, ~1 minute per step)

1) Show repository and evidence files

```bash
cd ~/Desktop/DevOps/DevSecOps
ls -la | sed -n '1,200p'
ls -la artifacts | sed -n '1,200p'
```

2) Grafana – login + health

- Open in browser: http://localhost:3000
- Credentials: admin / 1234

Quick check (terminal):

```bash
curl -sS -u admin:1234 http://localhost:3000/api/health | jq
```

3) Prometheus – targets and a query

Open http://localhost:9090 -> Status -> Targets (show falcosidekick)

Quick check (terminal):

```bash
curl -sS http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.service=="falcosidekick")'
curl -sS "http://localhost:9090/api/v1/query?query=falcosecurity_falcosidekick_falco_events_total" | jq
```

4) Trigger a runtime alert (safe)

```bash
kubectl run demo-shell --image=busybox --restart=Never -- sleep 3600
kubectl exec demo-shell -- ls /
# Wait a few seconds and show falcosidekick logs
kubectl logs -n falco deploy/falcosidekick --tail=200
```

If the alert is detected it will appear in Falco logs and (after a scrape) in Prometheus and Grafana.

5) Gatekeeper demonstration (admission control)

```bash
kubectl apply -f tp6/gatekeeper-test.yaml
# The apply should be denied. Show the saved evidence if needed:
sed -n '1,200p' tp6/gatekeeper-test.txt
```

6) Static scan artifacts (show Trivy)

```bash
jq -r '.Results[0] | {Target: .Target, Vulnerabilities: .Vulnerabilities[0:5]}' tp3/trivy-report.json
```

7) Host integrity (AIDE)

```bash
sed -n '1,120p' tp1/aide-check.txt
```

Safe verification commands (I ran these to test this runbook)
------------------------------------------------------------
- Grafana health: `curl -sS -u admin:1234 http://localhost:3000/api/health | jq`
- Prometheus targets (falcosidekick): `curl -sS http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.service=="falcosidekick")'`
- Falcosidekick metrics (first lines): `curl -sS http://127.0.0.1:2801/metrics | head -n 40`
- AIDE check head: `sed -n '1,80p' tp1/aide-check.txt`

Notes & troubleshooting
-----------------------
- Grafana uses default demo credentials; rotate in production.
- If a Prometheus query returns no data, wait one scrape interval or trigger a runtime alert (step 4).
- If falcosidekick metrics aren't appearing, ensure ServiceMonitor/annotations exist and Prometheus has the target UP.

Done
----
This file is the short runbook for your 10-minute demo. Use the commands above during the live run. If you want, I can also generate a 6-slide deck in `slides/` or run the "burst alerts" step now to populate Grafana panels live.
