#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: hudo
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/got3nks/amutorrent

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  python3 \
  python3-pip \
  make \
  g++
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Apprise (push notifications)"
$STD pip3 install --break-system-packages apprise
msg_ok "Installed Apprise"

fetch_and_deploy_gh_release "amutorrent" "got3nks/amutorrent" "tarball"

msg_info "Building Frontend"
cd /opt/amutorrent
$STD npm install
$STD npm run build
msg_ok "Built Frontend"

msg_info "Installing Server Dependencies"
cd /opt/amutorrent/server
$STD npm ci --omit=dev
msg_ok "Installed Server Dependencies"

msg_info "Setting up Directories"
mkdir -p /opt/amutorrent/server/data /opt/amutorrent/server/logs
msg_ok "Set up Directories"

msg_info "Configuring App"
cat <<EOF >/opt/amutorrent/.env
NODE_ENV=production
PORT=4000
RUNNING_IN_DOCKER=false
EOF
msg_ok "Configured App"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/amutorrent.service
[Unit]
Description=aMuTorrent Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/amutorrent
EnvironmentFile=/opt/amutorrent/.env
ExecStart=/usr/bin/node /opt/amutorrent/server/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now amutorrent
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
