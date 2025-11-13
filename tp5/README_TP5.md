TP5: Security Monitoring & Threat Detection (Falco + Wazuh + Prometheus/Grafana)

Overview
--------
This TP5 package provides runtime threat detection (Falco), security event correlation (Wazuh), Prometheus metrics and Grafana security dashboards. It's designed for a laptop/local lab environment — components are modular so you can enable only what you need.

Included files
- `install_falco.sh` - install Falco on Ubuntu 24.04 and enable JSON output
- `falco_rules.custom.yaml` - custom Falco rules tuned for DevSecOps lab (container breakout, suspicious shell, etc.)
- `falcosidekick_setup.md` - instructions to run Falcosidekick to forward Falco events and expose Prometheus metrics
- `wazuh_manager_install.md` - instructions to install Wazuh manager (optional, resource heavy)
- `prometheus_rules.yml` - Prometheus alerting rules for security events
- `grafana_security_dashboard.json` - Grafana dashboard JSON to import security panels
- `verify_tp5.sh` - script to verify Falco and basic metrics are available

Notes
- Wazuh manager is resource-heavy; in a laptop lab you can run Wazuh manager in a VM or skip it and forward logs to a lightweight ELK or Loki.
- Falco requires kernel compatibility (eBPF or kernel module). On Ubuntu 24.04, Falco apt package uses eBPF where possible.

Next steps
- After installing Falco, enable `falco_rules.custom.yaml` by placing it under `/etc/falco/falco_rules.local.yaml` and restart Falco.
- Start Falcosidekick (Docker recommended) to forward events to Prometheus/Grafana/Wazuh/Loki as desired.
