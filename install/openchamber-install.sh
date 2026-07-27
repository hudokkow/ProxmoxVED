#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/openchamber/openchamber

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

ARCH=$(arch_resolve x64 arm64)
fetch_and_deploy_gh_release "opencode" "anomalyco/opencode" "prebuild" "latest" "/usr/local/bin" "opencode-linux-${ARCH}.tar.gz"

OPENCODE_SERVER_PASSWORD=$(openssl rand -hex 16)

msg_info "Creating OpenCode Configuration"
mkdir -p /opt/opencode
cat <<EOF >/opt/opencode/.env
OPENCODE_SERVER_PASSWORD=${OPENCODE_SERVER_PASSWORD}
EOF
msg_ok "Created OpenCode Configuration"

OPENCHAMBER_UI_PASSWORD=$(openssl rand -hex 16)

msg_info "Installing OpenChamber"
$STD npm install -g @openchamber/web
msg_ok "Installed OpenChamber"

msg_info "Storing Version"
npm list -g @openchamber/web --depth=0 2>/dev/null | grep '@openchamber/web' | awk -F'@' '{print $NF}' | tr -d ' ' > ~/.openchamber
msg_ok "Stored Version"

msg_info "Creating OpenChamber Configuration"
mkdir -p /opt/openchamber
cat <<EOF >/opt/openchamber/.env
OPENCHAMBER_UI_PASSWORD=${OPENCHAMBER_UI_PASSWORD}
EOF
msg_ok "Created OpenChamber Configuration"

msg_info "Creating OpenCode Service"
cat <<EOF >/etc/systemd/system/opencode.service
[Unit]
Description=OpenCode Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/opencode
EnvironmentFile=/opt/opencode/.env
ExecStart=/usr/local/bin/opencode serve --port 4095 --hostname 127.0.0.1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now opencode
msg_ok "Created OpenCode Service"

msg_info "Creating OpenChamber Service"
cat <<EOF >/etc/systemd/system/openchamber.service
[Unit]
Description=OpenChamber Web Server
After=network.target opencode.service
Wants=opencode.service

[Service]
Type=simple
User=root
WorkingDirectory=/root
EnvironmentFile=/opt/openchamber/.env
Environment=OPENCODE_HOST=http://localhost:4095
Environment=OPENCODE_SKIP_START=true
ExecStart=/usr/bin/openchamber serve --port 80 --host 0.0.0.0 --foreground
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openchamber
msg_ok "Created OpenChamber Service"

motd_ssh
customize
cleanup_lxc
