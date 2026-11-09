#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/nesquena/hermes-webui

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

msg_info "Installing Hermes Agent"
$STD uv venv /opt/hermesagent --python 3.14
$STD uv pip install --python /opt/hermesagent/bin/python hermes-agent
msg_ok "Installed Hermes Agent"

fetch_and_deploy_gh_release "hermeswebui" "nesquena/hermes-webui" "tarball" "latest" "/opt/hermeswebui"

msg_info "Installing WebUI Dependencies"
$STD uv pip install --python /opt/hermesagent/bin/python -r /opt/hermeswebui/requirements.txt
msg_ok "Installed WebUI Dependencies"

msg_info "Configuring Hermes WebUI"
WEBUI_PASS=$(random_password)
cat <<EOF >/opt/hermeswebui/.env
HERMES_WEBUI_HOST=0.0.0.0
HERMES_WEBUI_PORT=80
HERMES_WEBUI_PASSWORD=${WEBUI_PASS}
HERMES_WEBUI_PYTHON=/opt/hermesagent/bin/python
EOF
chmod 600 /opt/hermeswebui/.env
msg_ok "Configured Hermes WebUI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hermeswebui.service
[Unit]
Description=HermesWebUI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hermeswebui
EnvironmentFile=/opt/hermeswebui/.env
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
