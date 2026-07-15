#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: ProxmoxVED Contributor (community-scripts)
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
$STD apt install -y nginx
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "livecodes" "live-codes/livecodes" "prebuild" "latest" "/var/www/livecodes" "livecodes-v*.tar.gz"

msg_info "Creating Nginx Site"
cat <<'EOF' >/etc/nginx/sites-available/livecodes
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /var/www/livecodes;
    index index.html;

    # SPA-style fallback so deep links and share URLs resolve to the app
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets (hashed filenames) aggressively
    location ~* \.(js|css|woff2?|ttf|eot|svg|png|jpg|jpeg|gif|ico|map)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
ln -sf /etc/nginx/sites-available/livecodes /etc/nginx/sites-enabled/livecodes
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
msg_ok "Created Nginx Site"

motd_ssh
customize
cleanup_lxc
