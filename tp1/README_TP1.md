TP1: Secure Foundation Setup (Ubuntu 24.04)

Overview
--------
This TP1 package explains and automates host hardening for Ubuntu 24.04 in a resource-conscious, repeatable manner. It includes:

- A hardening script: `harden_ubuntu24.sh` (run with sudo)
- SSH config snippet to place at `/etc/ssh/sshd_config.d/99-custom.conf`
- `fail2ban` jail local config
- `audit` rules sample
- `verify_baseline.sh` to validate controls

Note: Run the hardening script on a test VM first. These changes will modify SSH, firewall, audit and package settings.

Quick run (example):

sudo bash ./harden_ubuntu24.sh
sudo bash ./verify_baseline.sh

If you plan to integrate with Wazuh (TP5), set the variable `WAZUH_MANAGER` in the hardening script before registering the agent.

Resources
---------
- CIS Ubuntu 22/24 benchmarks
- Ubuntu unattended-upgrades documentation

