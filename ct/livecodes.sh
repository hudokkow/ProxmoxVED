#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/live-codes/livecodes

APP="LiveCodes"
var_tags="${var_tags:-dev-tools;code;playground}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/livecodes/build ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "livecodes" "live-codes/livecodes"; then
    msg_info "Stopping Service"
    systemctl stop livecodes
    systemctl stop caddy
    msg_ok "Stopped Service"

    msg_info "Updating LiveCodes (Patience)"
    cd /opt/livecodes
    $STD git pull
    LATEST_TAG=$(curl -s https://api.github.com/repos/live-codes/livecodes/releases/latest | jq -r '.tag_name')
    $STD git checkout "$LATEST_TAG"
    $STD npm ci
    $STD cp -r src/livecodes/html/sandbox server/src/sandbox
    SELF_HOSTED=true \
      SANDBOX_HOST_NAME="${IP}" \
      SANDBOX_PORT=8090 \
      BROADCAST_PORT=3030 \
      $STD npm run build:app
    cd server
    $STD npm ci
    msg_ok "Updated LiveCodes"

    msg_info "Starting Service"
    systemctl start caddy
    systemctl start livecodes
    msg_ok "Started Service"
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
echo -e "${GATEWAY}${BGN}http://${IP}:80${CL}"
