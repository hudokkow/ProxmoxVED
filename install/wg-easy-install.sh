#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/wg-easy/wg-easy

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  iptables \
  nftables \
  kmod \
  wireguard-tools \
  wireguard-go
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "wgeasy" "wg-easy/wg-easy" "tarball"

PNPM_VERSION=$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/wgeasy/package.json)
NODE_VERSION="24" NODE_MODULE="pnpm@${PNPM_VERSION:-12.21.0}" setup_nodejs

msg_info "Building wg-easy"
cd /opt/wgeasy/src
$STD pnpm install --frozen-lockfile
$STD pnpm build
cp -a .output/. /opt/wgeasy/
mkdir -p /opt/wgeasy/server/database/migrations
cp server/database/migrations/*.sql /opt/wgeasy/server/database/migrations/
rm -rf /opt/wgeasy/src/node_modules /opt/wgeasy/src/.output /opt/wgeasy/src/.nuxt
msg_ok "Built wg-easy"

msg_info "Configuring wg-easy"
mkdir -p /etc/wireguard
cat <<EOF >/opt/wgeasy/.env
PORT=80
HOST=0.0.0.0
INSECURE=true
WG_INTERFACE=wg0
EOF
msg_ok "Configured wg-easy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wgeasy.service
[Unit]
Description=wg-easy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wgeasy
EnvironmentFile=/opt/wgeasy/.env
ExecStartPre=-/usr/sbin/sysctl -w net.ipv4.ip_forward=1
ExecStartPre=-/usr/sbin/sysctl -w net.ipv4.conf.all.src_valid_mark=1
ExecStartPre=-/usr/sbin/sysctl -w net.ipv6.conf.all.forwarding=1
ExecStart=/usr/bin/node /opt/wgeasy/server/index.mjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wgeasy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
