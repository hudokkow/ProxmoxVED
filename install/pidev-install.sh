#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: hudo
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/earendil-works/pi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

ARCH=$(uname -m)
case "$ARCH" in
x86_64) AMI_ARCH="x64"; TTYD_ARCH="x86_64" ;;
aarch64) AMI_ARCH="arm64"; TTYD_ARCH="aarch64" ;;
*)
  msg_error "Unsupported architecture: $ARCH (pidev supports x86_64 and aarch64)"
  exit 1
  ;;
esac

msg_info "Installing Dependencies"
$STD apt install -y \
  jq
msg_ok "Installed Dependencies"

msg_info "Installing ttyd"
fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.${TTYD_ARCH}"
ln -sf /usr/local/bin/ttyd /usr/bin/ttyd
msg_ok "Installed ttyd"

msg_info "Installing pidev"
fetch_and_deploy_gh_release "pidev" "earendil-works/pi" "prebuild" "latest" "/opt/pidev" "pi-linux-${AMI_ARCH}.tar.gz"
ln -sf /opt/pidev/pi /usr/local/bin/pi
msg_ok "Installed pidev"

if [[ -z "${PI_API_KEY:-}" ]]; then
  read -rsp "LLM provider API key (e.g. ANTHROPIC_API_KEY, GITHUB_TOKEN, or OPENAI_API_KEY): " PI_API_KEY
  echo
fi
if [[ -z "${PI_API_KEY_NAME:-}" ]]; then
  read -rp "Environment variable name for the key [ANTHROPIC_API_KEY]: " PI_API_KEY_NAME
  PI_API_KEY_NAME="${PI_API_KEY_NAME:-ANTHROPIC_API_KEY}"
fi

msg_info "Configuring pidev"
mkdir -p /opt/pidev/data
cat <<EOF >/opt/pidev/pi.env
PI_CODING_AGENT_DIR=/opt/pidev/data
HOME=/opt/pidev/data
PI_OFFLINE=0
PI_TELEMETRY=0
${PI_API_KEY_NAME}=${PI_API_KEY}
EOF
chmod 600 /opt/pidev/pi.env
msg_ok "Configured pidev"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pi-ttyd.service
[Unit]
Description=pi coding agent (browser terminal via ttyd)
Documentation=https://pi.dev/docs/latest
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pidev/data
EnvironmentFile=/opt/pidev/pi.env
ExecStart=/usr/bin/ttyd -W -p 7681 /usr/local/bin/pi
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pi-ttyd
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
