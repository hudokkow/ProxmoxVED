#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/amule-org/amule

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install --no-install-recommends -y \
  build-essential \
  cmake \
  pkg-config \
  gettext \
  bison \
  flex \
  libcrypto++-dev \
  libboost-dev \
  libwxgtk3.2-dev \
  libpng-dev \
  zlib1g-dev \
  libgd-dev \
  libglib2.0-dev \
  libmaxminddb-dev \
  libupnp-dev
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "amule" "amule-org/amule" "prebuild" "latest" "/opt/amule" "aMule-*-src.tar.gz"

msg_info "Building aMule"
cd /opt/amule
mkdir -p build
cd build
$STD cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/amule \
  -DWX_GTK=3 \
  -DENABLE_AMULECMD=ON \
  -DENABLE_WEBSERVER=ON \
  -DENABLE_UPNP=ON \
  -DENABLE_IP2COUNTRY=ON
$STD make -j "$(nproc)"
$STD make install
$STD ldconfig
cd /opt/amule
rm -rf build
msg_ok "Built aMule"

msg_info "Configuring aMule"
mkdir -p /opt/amule/data/.aMule
cat <<EOF >/opt/amule/data/.aMule/amule.conf
[ExternalConnect]
AcceptExternalConnections=1
ECPort=4712
ECPassword=$(printf '%s' "$(tr -d '-' </proc/sys/kernel/random/uuid)" | md5sum | cut -d' ' -f1)

[WebServer]
Enabled=1
Password=$(printf '%s' "$(tr -d '-' </proc/sys/kernel/random/uuid)" | md5sum | cut -d' ' -f1)
PasswordLow=$(printf '%s' "$(tr -d '-' </proc/sys/kernel/random/uuid)" | md5sum | cut -d' ' -f1)
Port=4711
WebTemplate=php-default
UseGzip=1
UpnpWebServerEnabled=0

[GUI]
RemoteUsername=admin
EOF
chmod 600 /opt/amule/data/.aMule/amule.conf
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
Environment=HOME=/opt/amule/data
ExecStart=/opt/amule/bin/amuled --ec-daemon
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
