Falcosidekick setup (forward Falco events and expose Prometheus metrics)

Falcosidekick is a companion to Falco that can receive events and forward them to many outputs (Prometheus, Slack, Elasticsearch, Wazuh, Loki, etc.). It also exposes a Prometheus metrics endpoint.

Quick Docker run (recommended for lab):

```bash
# Run Falcosidekick and expose metrics on 2801
docker run -d --name falcosidekick \
  -p 2801:2801 \
  -e FALCO_OPTIONS="-r /etc/falco/falco_rules.local.yaml -o json_output=true" \
  -v /var/run/falco/falco.sock:/var/run/falco/falco.sock \
  -v /etc/falco:/etc/falco \
  falcosecurity/falcosidekick:latest
```

Alternatively, you can run Falco with a program_output that invokes falcosidekick as a binary. See Falcosidekick docs for details: https://github.com/falcosecurity/falcosidekick

Prometheus:
- Falcosidekick exposes `/metrics` on port 2801. Add a scrape config to Prometheus to collect these metrics.

Example Prometheus scrape config:

```yaml
- job_name: 'falcosidekick'
  static_configs:
    - targets: ['localhost:2801']
```

Grafana:
- Import the provided `grafana_security_dashboard.json` to visualize falco alerts and Wazuh events.

Wazuh integration:
- Falcosidekick can forward alerts to Wazuh via its API. Configure environment variables `WAZUH_URL`, `WAZUH_USER`, `WAZUH_PASS` when running the container.
