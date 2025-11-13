TP2: Secure CI Pipeline (SonarQube, OWASP Dependency-Check, Gitleaks)

Overview
--------
This TP2 package adds SAST, dependency scanning and secrets scanning to your Jenkins CI on Ubuntu 24.04. The approach favors Dockerized scanners to minimize host installs and preserve laptop resources.

Included files
- `sonarqube-docker-compose.yml` - run SonarQube locally using Docker Compose (Community edition)
- `install_tools.sh` - convenience script to install Docker, Docker Compose, and pull scanner images
- `gitleaks_scan.sh` - run Gitleaks secrets scanner
- `dependency_check_scan.sh` - run OWASP Dependency-Check (Docker)
- `sonar_scan.sh` - run SonarScanner (Docker)
- `jenkins_security_hardening.md` - guidance to harden Jenkins and configure credentials
- `Jenkinsfile` - full pipeline with security stages (secret scanning, SAST, dependency check, build, container scan placeholders)
- `verify_tp2.sh` - runs quick smoke tests for the scanners against the current repo

Quick run examples

1) Start SonarQube (optional, Docker required):

```bash
cd tp2
docker compose up -d
# Wait 1-2 minutes for SonarQube to be ready
```

2) Run a local secrets scan on your repo:

```bash
sudo bash ./gitleaks_scan.sh .
```

3) Run dependency check (Java/Maven target):

```bash
sudo bash ./dependency_check_scan.sh .
```

4) Run Sonar Scanner (requires SonarQube running and SONAR_TOKEN env):

```bash
export SONAR_HOST_URL=http://localhost:9000
export SONAR_LOGIN=<your_sonar_token>
sudo bash ./sonar_scan.sh .
```

Notes
- For Jenkins integration, add the SONAR token and other secrets to Jenkins Credentials (Secret text/username-password). Use the `withCredentials` block in the `Jenkinsfile`.
- Scanner containers are used to keep the host clean and ensure repeatability.

