#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/mintplex-labs/anything-llm

APP="AnythingLLM"
var_tags="${var_tags:-ai;chat;llm}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/anythingllm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
  $STD corepack enable

  if check_for_gh_release "anythingllm" "mintplex-labs/anything-llm"; then
    msg_info "Stopping Services"
    systemctl stop anythingllm
    systemctl stop anythingllm-collector
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp -r /opt/anythingllm/server/storage /opt/anythingllm_storage_backup
    cp /opt/anythingllm/server/.env /opt/anythingllm.env.backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "anythingllm" "mintplex-labs/anything-llm" "tarball"

    msg_info "Restoring Configuration"
    cp /opt/anythingllm.env.backup /opt/anythingllm/server/.env
    cp -r /opt/anythingllm_storage_backup/. /opt/anythingllm/server/storage
    rm -rf /opt/anythingllm_storage_backup /opt/anythingllm.env.backup
    msg_ok "Restored Configuration"

    msg_info "Building Frontend"
    cd /opt/anythingllm/frontend
    $STD yarn install --network-timeout 100000
    $STD yarn build
    msg_ok "Built Frontend"

    msg_info "Building Server"
    cd /opt/anythingllm/server
    $STD yarn install --production --network-timeout 100000
    $STD npx prisma generate --schema=./prisma/schema.prisma
    $STD npx prisma migrate deploy --schema=./prisma/schema.prisma
    msg_ok "Built Server"

    msg_info "Building Collector"
    cd /opt/anythingllm/collector
    $STD yarn install --production --network-timeout 100000
    msg_ok "Built Collector"

    msg_info "Setting up Storage"
    cp -r /opt/anythingllm/frontend/dist /opt/anythingllm/server/public
    msg_ok "Set up Storage"

    msg_info "Starting Services"
    systemctl start anythingllm
    systemctl start anythingllm-collector
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3001${CL}"
