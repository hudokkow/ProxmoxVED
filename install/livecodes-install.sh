#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: hudo
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
$STD apt install -y \
  caddy
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "livecodes" "live-codes/livecodes" "prebuild" "latest" "/opt/livecodes" "livecodes-v*.tar.gz"

msg_info "Configuring Caddy"
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/livecodes
    file_server
    encode gzip
    try_files {path} /index.html
}
EOF
msg_ok "Configured Caddy"

msg_info "Enabling and Starting Caddy"
systemctl enable -q --now caddy
msg_ok "Enabled and Started Caddy"

motd_ssh
customize
cleanup_lxc
