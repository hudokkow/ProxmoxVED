#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/MoonshotAI/kimi-code

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

NODE_VERSION="24" setup_nodejs

msg_info "Installing pnpm"
$STD npm install -g pnpm
msg_ok "Installed pnpm"

fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.$(arch_resolve "x86_64" "aarch64")"

fetch_and_deploy_gh_branch "kimicli" "MoonshotAI/kimi-code" "main" "/opt/kimicli"

msg_info "Installing Dependencies"
cd /opt/kimicli
$STD pnpm install
msg_ok "Installed Dependencies"

msg_info "Building Kimi Code"
$STD pnpm run build
msg_ok "Built Kimi Code"

ln -sf /opt/kimicli/apps/kimi-code/dist/main.mjs /usr/local/bin/kimi
msg_ok "Linked binary"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/kimicli.service
[Unit]
Description=Kimi Code CLI Web Terminal
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ttyd -W -T xterm-256color -p 80 /usr/local/bin/kimi
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kimicli
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
