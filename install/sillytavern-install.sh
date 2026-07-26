#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://sillytavern.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "sillytavern" "SillyTavern/SillyTavern" "tarball"

msg_info "Creating Data Directory"
mkdir -p /opt/sillytavern/data
msg_ok "Created Data Directory"

msg_info "Creating Configuration"
cat <<EOF >/opt/sillytavern/config.yaml
listen: true
listenAddress:
  ipv4: 0.0.0.0
port: 80
whitelistMode: true
whitelist:
  - ::/0
  - 0.0.0.0/0
EOF
msg_ok "Created Configuration"

msg_info "Installing Application"
cd /opt/sillytavern
$STD npm ci --no-audit --no-fund --loglevel=error --no-progress --omit=dev --ignore-scripts
$STD npm cache clean --force
msg_ok "Installed Application"

msg_info "Initializing Configuration"
$STD npm run init
msg_ok "Initialized Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/sillytavern.service
[Unit]
Description=SillyTavern Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/sillytavern
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/sillytavern/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sillytavern
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
