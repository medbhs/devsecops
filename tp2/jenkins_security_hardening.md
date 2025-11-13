Jenkins Security Hardening (TP2)

Recommendations to harden Jenkins (local training instance)

1) Upgrade Jenkins to recent LTS and keep plugins up to date.
2) Use Security Realm + Matrix-based security:
   - Create non-admin users for builds and operators
   - Give only required permissions to service accounts
3) Enable CSRF Protection and agent-to-master security.
4) Use the Credentials Plugin to store all secrets (tokens, keys, passwords):
   - Store Sonar token as "Secret text" with ID `sonar-token`
   - Store DockerHub creds as "Username with password" id `dockerhub`
   - Store Cosign key or password as `cosign-key`
5) Configure credentials binding plugin and use `withCredentials` in pipelines.
6) Limit plugin installation: allow only curated plugins. Use local update center if needed.
7) Configure node labels and limit which agents can run production jobs.
8) Configure global Pipeline: Groovy sandbox and script approval where necessary.
9) Configure audit logging (Jenkins audit-trail plugin) and forward logs to Wazuh/ELK for SIEM.
10) Backup Jenkins config and credentials regularly and store encryption keys securely.

Useful plugins for DevSecOps pipeline:
- Credentials Binding Plugin
- Role-based Authorization Strategy or Matrix Authorization
- OWASP Markup Formatter
- Pipeline: Multibranch
- Git, GitHub, GitHub Branch Source
- SonarQube Scanner Plugin (optional)
- Warnings NG
- Audit Trail

Jenkins master security CLI hints (run on the Jenkins host):
- Enable agent to master access control (Manage Jenkins -> Configure Global Security)
- Limit permitted scripts and approve needed signatures via script-security plugin

Credential usage example in pipeline:
```
withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
  sh "./tp2/sonar_scan.sh ."
}
```
