#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/jmfederico/pi-web

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Pi Web"
fetch_and_deploy_gh_release "pi-web" "jmfederico/pi-web" "tarball"

msg_info "Building Pi Web"
cd /opt/pi-web
$STD npm install
$STD npm run build
msg_ok "Built Pi Web"

msg_info "Creating Config"
[ -f /root/.pi-web ] && rm -f /root/.pi-web
mkdir -p /root/.config/pi-web /root/.pi /root/.pi-web
cat <<EOF >/root/.config/pi-web/config.json
{
  "host": "0.0.0.0",
  "port": 80,
  "allowedHosts": []
}
EOF
msg_ok "Created Config"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/pi-web-sessiond.service
[Unit]
Description=Pi Web Session Daemon
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pi-web
ExecStart=/usr/bin/node /opt/pi-web/dist/server/sessiond.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/pi-web.service
[Unit]
Description=Pi Web Server
After=network.target pi-web-sessiond.service
Wants=pi-web-sessiond.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pi-web
ExecStart=/usr/bin/node /opt/pi-web/dist/server/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pi-web-sessiond pi-web
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
