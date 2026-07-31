#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/Swetrix/swetrix

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
  nginx \
  python3 \
  redis-server
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

setup_clickhouse

msg_info "Configuring Credentials"
REDIS_PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
CLICKHOUSE_PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
cat <<EOF >>/etc/redis/redis.conf
requirepass ${REDIS_PASSWORD}
EOF
$STD systemctl restart redis-server
cat <<EOF >/etc/clickhouse-server/users.d/password.xml
<clickhouse>
  <users>
    <default>
      <password>${CLICKHOUSE_PASSWORD}</password>
    </default>
  </users>
</clickhouse>
EOF
$STD systemctl restart clickhouse-server
msg_ok "Configured Credentials"

msg_info "Configuring ClickHouse"
cat <<EOF >/etc/clickhouse-server/config.d/network.xml
<clickhouse>
    <listen_host>127.0.0.1</listen_host>
</clickhouse>
EOF
cat <<EOF >/etc/clickhouse-server/config.d/preserve-ram-config.xml
<clickhouse>
  <mark_cache_size>536870912</mark_cache_size>
  <concurrent_threads_soft_limit_num>1</concurrent_threads_soft_limit_num>
</clickhouse>
EOF
cat <<EOF >/etc/clickhouse-server/config.d/reduce-logs.xml
<clickhouse>
  <logger>
    <level>warning</level>
    <console>true</console>
  </logger>
  <query_thread_log remove="remove"/>
  <query_log remove="remove"/>
  <text_log remove="remove"/>
  <trace_log remove="remove"/>
  <metric_log remove="remove"/>
  <asynchronous_metric_log remove="remove"/>
  <session_log remove="remove"/>
  <part_log remove="remove"/>
  <processors_profile_log remove="remove"/>
  <asynchronous_insert_log remove="remove"/>
  <query_metric_log remove="remove"/>
  <opentelemetry_span_log remove="remove"/>
</clickhouse>
EOF
cat <<EOF >/etc/clickhouse-server/users.d/preserve-ram-user.xml
<clickhouse>
  <profiles>
    <default>
      <max_block_size>2048</max_block_size>
      <max_download_threads>1</max_download_threads>
      <input_format_parallel_parsing>0</input_format_parallel_parsing>
      <output_format_parallel_formatting>0</output_format_parallel_formatting>
    </default>
  </profiles>
</clickhouse>
EOF
cat <<EOF >/etc/clickhouse-server/users.d/async-insert.xml
<clickhouse>
  <profiles>
    <default>
      <async_insert>0</async_insert>
    </default>
  </profiles>
</clickhouse>
EOF
$STD systemctl restart clickhouse-server
msg_ok "Configured ClickHouse"

fetch_and_deploy_gh_release "swetrix" "Swetrix/swetrix" "tarball" "latest" "/opt/swetrix" "" "v"

msg_info "Creating Environment"
SECRET_KEY_BASE=$(openssl rand -base64 48)
cat <<EOF >/opt/swetrix/backend/.env
NODE_ENV=production
IS_PRIMARY_NODE=true
SECRET_KEY_BASE=${SECRET_KEY_BASE}
DISABLE_REGISTRATION=true
IP_GEOLOCATION_DB_PATH=/opt/swetrix/backend/ip-geolocation-db.mmdb
CLIENT_URL=http://${LOCAL_IP}
BASE_URL=http://${LOCAL_IP}
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_USER=default
REDIS_PASSWORD=${REDIS_PASSWORD}
CLICKHOUSE_HOST=http://127.0.0.1
CLICKHOUSE_USER=default
CLICKHOUSE_PORT=8123
CLICKHOUSE_DATABASE=analytics
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
SMTP_MOCK=false
EOF
cat <<EOF >/opt/swetrix/web/.env
NODE_ENV=production
__SELFHOSTED=true
BASE_URL=http://${LOCAL_IP}
API_ORIGIN=http://127.0.0.1:5005
HOST=127.0.0.1
PORT=3000
EOF
msg_ok "Created Environment"

msg_info "Building API"
cd /opt/swetrix/backend
$STD npm ci --force
$STD npm run deploy:community
$STD node ./meta/dbip-free-sync.js
msg_ok "Built API"

msg_info "Building Web"
cd /opt/swetrix/web
$STD npm ci
$STD npm run build
msg_ok "Built Web"

msg_info "Initializing ClickHouse"
cd /opt/swetrix/backend
$STD npm run clickhouse:initialise
msg_ok "Initialized ClickHouse"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/swetrix
map $http_upgrade $connection_upgrade {
  default upgrade;
  ""      close;
}

server {
  listen 80;
  listen [::]:80;
  server_name _;

  client_max_body_size 16m;

  location /backend/ {
    proxy_pass http://127.0.0.1:5005/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;

    proxy_buffering on;
    proxy_buffer_size 256k;
    proxy_buffers 64 512k;
    proxy_busy_buffers_size 16m;
    proxy_temp_file_write_size 16m;
    proxy_max_temp_file_size 1024m;
  }

  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
  }

  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
}
EOF
ln -sf /etc/nginx/sites-available/swetrix /etc/nginx/sites-enabled/swetrix
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/swetrix-api.service
[Unit]
Description=Swetrix API
After=network.target clickhouse-server.service redis-server.service
Wants=clickhouse-server.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/swetrix/backend
EnvironmentFile=/opt/swetrix/backend/.env
ExecStart=/usr/bin/node /opt/swetrix/backend/dist/main
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/swetrix-web.service
[Unit]
Description=Swetrix Web Frontend
After=network.target swetrix-api.service
Wants=swetrix-api.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/swetrix/web
EnvironmentFile=/opt/swetrix/web/.env
ExecStart=/usr/bin/node /opt/swetrix/web/node_modules/.bin/react-router-serve /opt/swetrix/web/build/server/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now swetrix-api
systemctl enable -q --now swetrix-web
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
