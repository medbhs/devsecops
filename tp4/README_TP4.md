TP4: Enhanced Code Quality + Security (SonarQube rules, Quality Gates, License Scanning)

Overview
--------
This TP4 package configures SonarQube for security-focused analysis, integrates OWASP Dependency-Check results, and adds license compliance scanning guidance. It provides automation scripts to import rules, set quality gates (fail build on critical issues), and track security debt.

Included files
- `sonar_quality_gate.json` - example SonarQube quality gate definition
- `sonar_security_profile.xml` - example rules export for SonarQube (security rules/OWASP)
- `import_sonar_profile.sh` - script to import the profile into local SonarQube
- `integrate_dependency_check.sh` - parse and upload Dependency-Check report to Sonar or store in artifact
- `license_scanning.md` - guidance for license scanning (fossology/spdx)
- `jenkins_quality_gate_stage.groovy` - snippet to add to Jenkinsfile to fail builds on quality gate

