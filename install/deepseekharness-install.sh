#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/deepseek-ai/deepseek-harness

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

msg_info "Installing pnpm"
$STD npm install -g pnpm
PNPM=$(command -v pnpm)
ln -sf "$PNPM" /usr/local/bin/pnpm
msg_ok "Installed pnpm"

GH_INCLUDE_PRERELEASE=1 fetch_and_deploy_gh_release "deepseekharness" "deepseek-ai/deepseek-harness" "tarball"

msg_info "Building Application"
cd /opt/deepseekharness
$STD pnpm install
$STD pnpm run build
msg_ok "Built Application"

msg_info "Creating Configuration"
cat <<EOF >/opt/deepseekharness/.env
NODE_ENV=production
EOF
msg_ok "Created Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/deepseekharness.service
[Unit]
Description=DeepSeekHarness Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/deepseekharness
Environment=NODE_ENV=production
ExecStart=/usr/local/bin/pnpm dsh web
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now deepseekharness
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc