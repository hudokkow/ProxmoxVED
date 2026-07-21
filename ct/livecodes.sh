#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: hudo
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/live-codes/livecodes

APP="LiveCodes"
var_tags="${var_tags:-code;playground;web}"
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

  if [[ ! -d /opt/livecodes ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "livecodes" "live-codes/livecodes"; then
    msg_info "Stopping Service"
    systemctl stop caddy
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /etc/caddy/Caddyfile /opt/livecodes.caddyfile.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "livecodes" "live-codes/livecodes" "prebuild" "latest" "/opt/livecodes" "livecodes-v*.tar.gz"

    msg_info "Restoring Configuration"
    cp /opt/livecodes.caddyfile.bak /etc/caddy/Caddyfile
    rm -f /opt/livecodes.caddyfile.bak
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start caddy
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
