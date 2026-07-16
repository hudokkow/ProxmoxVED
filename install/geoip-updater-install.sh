#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/crazy-max/geoip-updater

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

ARCH=$(arch_resolve x86_64 aarch64)

fetch_and_deploy_gh_release "geoip-updater" "crazy-max/geoip-updater" "prebuild" "latest" "/usr/local/bin/geoip-updater" "geoip-updater_*_linux_${ARCH}.tar.gz"
msg_ok "Installed geoip-updater"

msg_info "Configuring geoip-updater"
mkdir -p /usr/local/bin/geoip-updater /usr/local/bin/geoip-updater/data
cat <<EOF >/etc/geoip-updater/geoip-updater.env
EDITION_IDS=GeoLite2-ASN,GeoLite2-City,GeoLite2-Country
LICENSE_KEY=
DOWNLOAD_PATH=/usr/local/bin/geoip-updater/data
SCHEDULE=0 0 * * *
LOG_LEVEL=info
EOF
chmod 600 /etc/geoip-updater/geoip-updater.env
msg_ok "Configured geoip-updater"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/geoip-updater.service
[Unit]
Description=geoip-updater
Documentation=https://crazymax.dev/geoip-updater/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/geoip-updater/geoip-updater.env
ExecStart=/usr/local/bin/geoip-updater/geoip-updater
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now geoip-updater
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
