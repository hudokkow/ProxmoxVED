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
cat <<EOF >/opt/amule_data/.aMule/amule.conf
[ExternalConnect]
AcceptExternalConnections=1
ECPort=4712
ECPassword=$(openssl rand -hex 16)

[WebServer]
Enabled=1
Password=$(openssl rand -hex 16)
PasswordLow=$(openssl rand -hex 16)
Port=4711
WebTemplate=php-default
UseGzip=1
UpnpWebServerEnabled=0

[GUI]
RemoteUsername=admin
EOF
chmod 600 /opt/amule_data/.aMule/amule.conf
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
ExecStart=/opt/amule/amuled --ec-daemon
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
