#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/NousResearch/hermes-agent

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  ripgrep
msg_ok "Installed Dependencies"

NODE_VERSION="26" setup_nodejs
PYTHON_VERSION="3.14" setup_uv
setup_ffmpeg

fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.$(arch_resolve "x86_64" "aarch64")"

msg_info "Installing Hermes Agent"
$STD uv venv /opt/hermes-agent --python 3.14
$STD uv pip install --python /opt/hermes-agent/bin/python hermes-agent
msg_ok "Installed Hermes Agent"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hermesagent.service
[Unit]
Description=HermesAgent Web Terminal
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ttyd -W -T xterm-256color -i 0.0.0.0 -p 80 /opt/hermes-agent/bin/hermes
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hermesagent
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
