#!/usr/bin/env bash
# Harden Ubuntu 24.04 - resource conscious baseline
# Run as root or with sudo: sudo bash ./harden_ubuntu24.sh
set -euo pipefail

WAZUH_MANAGER="" # optionally set to Wazuh manager IP or hostname to register agent
ADMIN_USER="$(whoami)"

echo "[+] Updating packages"
apt update && apt upgrade -y

echo "[+] Installing baseline security packages"
apt install -y --no-install-recommends auditd aide fail2ban ufw unattended-upgrades apt-listchanges curl gnupg lsb-release

# Enable unattended upgrades
echo "[+] Enabling unattended-upgrades"
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    \"${distro_id}:${distro_codename}-security\";
};
Unattended-Upgrade::Automatic-Reboot "false";
EOF

dpkg-reconfigure -f noninteractive unattended-upgrades || true

# UFW basic rules
echo "[+] Configuring UFW"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw --force enable

# SSH hardening - create drop-in file (safe approach)
SSH_DROPIN=/etc/ssh/sshd_config.d/99-custom.conf
echo "[+] Writing SSH hardening to $SSH_DROPIN"
cat > "$SSH_DROPIN" <<'EOF'
# Custom SSH hardening overrides
Port 22
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
AllowUsers $ADMIN_USER
# LogLevel INFO
EOF

# Apply SSH changes (reload)
if systemctl is-active --quiet sshd; then
  systemctl reload sshd || systemctl restart sshd
fi

# Auditd configuration - ensure persistent logging
echo "[+] Configuring auditd"
sed -i 's/^#max_log_file_action.*/max_log_file_action = ROTATE/' /etc/audit/auditd.conf || true
systemctl enable --now auditd

# AIDE initialization
echo "[+] Initializing AIDE"
if [ ! -f /var/lib/aide/aide.db.gz ]; then
  aideinit || true
  cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz || true
fi

# Fail2Ban configuration
echo "[+] Writing fail2ban jail.local"
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 600
findtime  = 600
maxretry = 5

[sshd]
enabled = true

EOF
systemctl enable --now fail2ban

# Sysctl hardening (network + kernel)
echo "[+] Applying sysctl hardening"
cat > /etc/sysctl.d/99-custom-security.conf <<'EOF'
# Prevent IP forwarding
net.ipv4.ip_forward = 0
# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
# Enable tcp syncookies
net.ipv4.tcp_syncookies = 1
EOF
sysctl --system

# Remove or disable unused services (example list) - adjust to your environment
SERVICES_TO_DISABLE=(snapd cups avahi-daemon)
echo "[+] Disabling unused services: ${SERVICES_TO_DISABLE[*]}"
for s in "${SERVICES_TO_DISABLE[@]}"; do
  if systemctl list-unit-files | grep -q "^$s"; then
    systemctl disable --now "$s" || true
  fi
done

# Create basic audit rules file (atomic)
cat > /etc/audit/rules.d/99-security.rules <<'EOF'
# Audit configuration - track important events
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k actions
-w /var/log/auth.log -p wa -k logins
-a always,exit -F arch=b64 -S execve -k exec
EOF
augenrules --load || true

# Optionally register Wazuh agent if manager provided
if [ -n "$WAZUH_MANAGER" ]; then
  echo "[+] Installing Wazuh agent and registering with manager $WAZUH_MANAGER"
  # Wazuh repository and agent install (lightweight) - adjust for local manager
  wget -qO - https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh-archive-keyring.gpg || true
  echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list
  apt update
  apt install -y wazuh-agent
  sed -i "s/^MANAGER:.*/MANAGER="$WAZUH_MANAGER"/" /var/ossec/etc/ossec.conf || true
  systemctl enable --now wazuh-agent || true
fi

# Final OS audit info
echo "[+] Hardening complete. Reboot recommended for all kernel/sysctl changes to settle."

echo "[+] Summary: UFW enabled, SSH drop-in written to $SSH_DROPIN, auditd, aide, fail2ban configured."
