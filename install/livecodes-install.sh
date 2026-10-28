#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
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
msg_ok "Installed LiveCodes"

msg_info "Creating Nginx Site"
cat <<EOF >/etc/nginx/sites-available/livecodes
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /var/www/livecodes;
    index index.html;

    access_log /var/log/nginx/livecodes_access.log;
    error_log /var/log/nginx/livecodes_error.log;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|woff2?|ttf|eot|svg|png|jpg|jpeg|gif|ico|map)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
nginx_enable_site "livecodes"
msg_ok "Created Nginx Site"

motd_ssh
customize
cleanup_lxc
