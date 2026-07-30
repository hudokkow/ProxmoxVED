#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/itayinbarr/little-coder

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

TTYD_ARCH=$(arch_resolve x86_64 aarch64)
fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.${TTYD_ARCH}"

msg_info "Installing Application"
npm config set prefix /usr/local
$STD npm install -g little-coder
msg_ok "Installed Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/littlecoder-ttyd.service
[Unit]
Description=littlecoder (browser terminal via ttyd)
Documentation=https://github.com/itayinbarr/little-coder
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/ttyd -W -T xterm-256color -p 80 /usr/local/bin/little-coder
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now littlecoder-ttyd
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
