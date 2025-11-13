#!/usr/bin/env bash
# Verify baseline hardening settings
set -euo pipefail

echo "[+] UFW status"
ufw status verbose || true

echo "[+] SSHd drop-in files"
ls -l /etc/ssh/sshd_config.d || true

echo "[+] sshd config checks"
sshd -T | grep -E "permitrootlogin|passwordauthentication|allowtcpforwarding|logingrasstime" || true

echo "[+] auditd status"
systemctl is-active --quiet auditd && echo "auditd active" || echo "auditd not active"

echo "[+] AIDE DB presence"
if [ -f /var/lib/aide/aide.db.gz ]; then
  echo "AIDE DB present"
else
  echo "AIDE DB missing - run aideinit as root"
fi

echo "[+] fail2ban status"
systemctl is-active --quiet fail2ban && echo "fail2ban active" || echo "fail2ban not active"

echo "[+] Checking for core audit rules"
auditctl -l || true

