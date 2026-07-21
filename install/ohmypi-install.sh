#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/can1357/oh-my-pi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

TTYD_ARCH=$(arch_resolve x86_64 aarch64)
fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.${TTYD_ARCH}"

ARCH=$(arch_resolve x64 arm64)
fetch_and_deploy_gh_release "ohmypi" "can1357/oh-my-pi" "singlefile" "latest" "/usr/local/bin" "omp-linux-${ARCH}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ohmypi-ttyd.service
[Unit]
Description=Oh-My-Pi (browser terminal via ttyd)
Documentation=https://omp.sh/docs
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/ttyd -W -T xterm-256color -p 80 /usr/local/bin/ohmypi
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ohmypi-ttyd
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
