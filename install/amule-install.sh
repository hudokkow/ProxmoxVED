#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/amule-org/amule

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "amule" "amule-org/amule" "prebuild" "latest" "/opt/amule" "aMule-*-Linux-$(arch_resolve "x64" "arm64")-static.tar.gz"

msg_info "Configuring aMule"
mkdir -p /opt/amule_data/.aMule
ADMIN_PASS=$(random_password)
EC_PASS=$(random_password)
cat <<EOF >/opt/amule_data/.env
AMULE_ADMIN_PASSWORD=${ADMIN_PASS}
AMULE_EC_PASSWORD=${EC_PASS}
EOF
cat <<EOF >/opt/amule_data/.aMule/amule.conf
[ExternalConnect]
AcceptExternalConnections=1
ECPort=4712
ECPassword=$(printf '%s' "$EC_PASS" | md5sum | cut -d' ' -f1)

[AmuleApi]
Enabled=1
BindAddress=0.0.0.0
HttpPort=80
EOF
chmod 600 /opt/amule_data/.env /opt/amule_data/.aMule/amule.conf
printf '%s\n' "$ADMIN_PASS" | $STD /opt/amule/amuleapi --config-dir=/opt/amule_data/.aMule --set-admin-pass-stdin
msg_ok "Configured aMule"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/amuled.service
[Unit]
Description=aMule Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment=HOME=/opt/amule_data
ExecStart=/opt/amule/amuled -d
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now amuled
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
