#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/live-codes/livecodes

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

msg_info "Installing Caddy"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | $STD gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | $STD tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
$STD apt update
$STD apt install -y caddy
msg_ok "Installed Caddy"

msg_info "Cloning LiveCodes"
LATEST_TAG=$(curl -s https://api.github.com/repos/live-codes/livecodes/releases/latest | jq -r '.tag_name')
$STD git clone --depth 1 --branch "$LATEST_TAG" https://github.com/live-codes/livecodes.git /opt/livecodes
msg_ok "Cloned LiveCodes"

msg_info "Building LiveCodes (Patience)"
cd /opt/livecodes
$STD npm ci
$STD cp -r src/livecodes/html/sandbox server/src/sandbox
SELF_HOSTED=true \
  SANDBOX_HOST_NAME="${IP}" \
  SANDBOX_PORT=8090 \
  BROADCAST_PORT=3030 \
  $STD npm run build:app
msg_ok "Built LiveCodes"

msg_info "Installing Server Dependencies"
cd /opt/livecodes/server
$STD npm ci
msg_ok "Installed Server Dependencies"

msg_info "Creating Caddy Site"
cat <<EOF >/etc/caddy/Caddyfile
{
    log {
        level WARN
    }
}

:80 {
    header -Server
    encode
    reverse_proxy localhost:443
}
EOF
msg_ok "Created Caddy Site"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/livecodes.service
[Unit]
Description=LiveCodes Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/livecodes
Environment=SELF_HOSTED=true
Environment=HOST_NAME=${IP}
Environment=PORT=443
Environment=SANDBOX_HOST_NAME=${IP}
Environment=SANDBOX_PORT=8090
Environment=SELF_HOSTED_SHARE=false
Environment=SELF_HOSTED_BROADCAST=true
Environment=BROADCAST_PORT=3030
ExecStart=/usr/bin/node /opt/livecodes/server/src/app.ts
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now livecodes
$STD systemctl enable -q --now caddy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
