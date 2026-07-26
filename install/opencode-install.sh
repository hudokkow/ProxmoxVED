#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/anomalyco/opencode

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

ARCH=$(arch_resolve x64 arm64)
fetch_and_deploy_gh_release "opencode" "anomalyco/opencode" "prebuild" "latest" "/usr/local/bin" "opencode-linux-${ARCH}.tar.gz"

OPENCODE_SERVER_PASSWORD=$(openssl rand -hex 16)

msg_info "Creating Configuration"
mkdir -p /opt/opencode
cat <<EOF >/opt/opencode/.env
OPENCODE_SERVER_PASSWORD=${OPENCODE_SERVER_PASSWORD}
EOF
msg_ok "Created Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/opencode.service
[Unit]
Description=OpenCode Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/opencode
EnvironmentFile=/opt/opencode/.env
ExecStart=/usr/local/bin/opencode serve --port 80 --hostname 0.0.0.0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now opencode
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
