#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: hudo
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/crazy-max/geoip-updater

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

ARCH=$(uname -m)
case "$ARCH" in
x86_64) AMI_ARCH="amd64" ;;
aarch64) AMI_ARCH="arm64" ;;
*)
  msg_error "Unsupported architecture: $ARCH (geoip-updater supports x86_64 and aarch64)"
  exit 1
  ;;
esac

msg_info "Installing geoip-updater"
fetch_and_deploy_gh_release "geoip-updater" "crazy-max/geoip-updater" "prebuild" "latest" "/opt/geoip-updater" "geoip-updater_*_linux_${AMI_ARCH}.tar.gz"
ln -sf /opt/geoip-updater/geoip-updater /usr/local/bin/geoip-updater
msg_ok "Installed geoip-updater"

if [[ -z "${LICENSE_KEY:-}" ]]; then
  read -rsp "MaxMind License Key (https://www.maxmind.com/en/accounts/current/license-key): " LICENSE_KEY
  echo
fi
if [[ -z "${EDITION_IDS:-}" ]]; then
  read -rp "Edition IDs to download [GeoLite2-ASN,GeoLite2-City,GeoLite2-Country]: " EDITION_IDS
  EDITION_IDS="${EDITION_IDS:-GeoLite2-ASN,GeoLite2-City,GeoLite2-Country}"
fi

msg_info "Configuring geoip-updater"
mkdir -p /etc/geoip-updater /opt/geoip-updater/data
cat <<EOF >/etc/geoip-updater/geoip-updater.env
EDITION_IDS=${EDITION_IDS}
LICENSE_KEY=${LICENSE_KEY}
DOWNLOAD_PATH=/opt/geoip-updater/data
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
ExecStart=/usr/local/bin/geoip-updater
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
