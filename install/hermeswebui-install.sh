#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
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
  ffmpeg \
  ripgrep
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

UV_PYTHON="3.11" setup_uv

msg_info "Installing Hermes Agent"
$STD uv venv /opt/hermesagent --python 3.11
$STD uv pip install --python /opt/hermesagent hermes-agent
msg_ok "Installed Hermes Agent"

fetch_and_deploy_gh_release "hermeswebui" "nesquena/hermes-webui" "tarball" "latest" "/opt/hermeswebui"

msg_info "Installing WebUI Dependencies"
$STD uv pip install --python /opt/hermesagent -r /opt/hermeswebui/requirements.txt
msg_ok "Installed WebUI Dependencies"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hermeswebui.service
[Unit]
Description=HermesWebUI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hermeswebui
Environment=HERMES_WEBUI_PORT=80
Environment=HERMES_WEBUI_HOST=0.0.0.0
Environment=HERMES_WEBUI_PYTHON=/opt/hermesagent/bin/python
ExecStart=/opt/hermesagent/bin/python /opt/hermeswebui/server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hermeswebui
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc