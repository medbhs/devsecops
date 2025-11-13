SonarQube Security Rules & Policies Notes

- SonarQube with the Security plugin (commercial) provides advanced SAST rules; use open-source community rules and SQALE-based security rules where possible.
- Enable rules that map to OWASP Top 10 and CWE categories.
- Configure 'New Code' baseline: gate applies only to new code to reduce noise.
- Track security debt through Sonar's remediation estimation and schedule periodic reviews.

Tip: For education, set the gate to fail on new critical/blocker vulnerabilities while allowing developers to triage legacy issues.
