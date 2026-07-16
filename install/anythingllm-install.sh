#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Hudo (hudo)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/mintplex-labs/anything-llm

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
  git \
  python3 \
  pkg-config \
  chromium \
  chromium-common \
  fonts-liberation \
  libnss3 \
  libxcomposite1 \
  libxdamage1 \
  libxrandr2 \
  libxfixes3 \
  libxkbcommon0 \
  libgbm1
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
$STD corepack enable

fetch_and_deploy_gh_release "anythingllm" "mintplex-labs/anything-llm" "tarball"

msg_info "Installing Application"
cd /opt/anythingllm
cat <<EOF >server/.env
SERVER_PORT=3001
NODE_ENV=production
JWT_SECRET="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
SIG_KEY="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-40)"
SIG_SALT="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-40)"
STORAGE_DIR="/opt/anythingllm/server/storage"
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
EOF

msg_info "Building Frontend"
cd /opt/anythingllm/frontend
$STD yarn install --network-timeout 100000
$STD yarn build
msg_ok "Built Frontend"

msg_info "Building Server"
cd /opt/anythingllm/server
$STD yarn install --production --network-timeout 100000
$STD npx prisma generate --schema=./prisma/schema.prisma
msg_ok "Built Server"

msg_info "Building Collector"
cd /opt/anythingllm/collector
$STD yarn install --production --network-timeout 100000
msg_ok "Built Collector"

msg_info "Setting up Storage"
cp -r /opt/anythingllm/frontend/dist /opt/anythingllm/server/public
cd /opt/anythingllm/server
$STD npx prisma migrate deploy --schema=./prisma/schema.prisma
mkdir -p /opt/anythingllm/server/storage
msg_ok "Set up Storage"
msg_ok "Installed Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/anythingllm.service
[Unit]
Description=AnythingLLM Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anythingllm/server
EnvironmentFile=/opt/anythingllm/server/.env
ExecStart=/usr/bin/node /opt/anythingllm/server/index.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/anythingllm-collector.service
[Unit]
Description=AnythingLLM Collector Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anythingllm/collector
Environment=NODE_ENV=production
Environment=PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ExecStart=/usr/bin/node /opt/anythingllm/collector/index.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now anythingllm
systemctl enable -q --now anythingllm-collector
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
