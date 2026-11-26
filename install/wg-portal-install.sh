#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/h44z/wg-portal

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
  openresolv \
  wireguard-tools
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "wgportal" "h44z/wg-portal" "singlefile" "latest" "/opt/wgportal" "wg-portal_linux_$(arch_resolve "amd64" "arm64")"

msg_info "Configuring WireGuard Portal"
mkdir -p /etc/wireguard /opt/wgportal-data
cat <<EOF >/opt/wgportal.env
WG_PORTAL_WEB_LISTENING_ADDRESS=:80
WG_PORTAL_WEB_EXTERNAL_URL=http://${LOCAL_IP}
WG_PORTAL_DATABASE_DSN=/opt/wgportal-data/sqlite.db
WG_PORTAL_WEB_SESSION_SECRET=$(random_password 32)
WG_PORTAL_WEB_CSRF_SECRET=$(random_password 32)
EOF
msg_ok "Configured WireGuard Portal"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wgportal.service
[Unit]
Description=WireGuard Portal
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wgportal
EnvironmentFile=/opt/wgportal.env
ExecStartPre=-/usr/sbin/sysctl -w net.ipv4.ip_forward=1
ExecStartPre=-/usr/sbin/sysctl -w net.ipv4.conf.all.src_valid_mark=1
ExecStartPre=-/usr/sbin/sysctl -w net.ipv6.conf.all.forwarding=1
ExecStart=/opt/wgportal/wgportal
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wgportal
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
