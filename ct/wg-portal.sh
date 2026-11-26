#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/h44z/wg-portal

APP="wg-portal"
var_tags="${var_tags:-vpn;network;wireguard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/wgportal ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wgportal" "h44z/wg-portal"; then
    msg_info "Stopping WireGuard Portal"
    systemctl stop wgportal
    msg_ok "Stopped WireGuard Portal"

    create_backup /opt/wgportal.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wgportal" "h44z/wg-portal" "singlefile" "latest" "/opt/wgportal" "wg-portal_linux_$(arch_resolve "amd64" "arm64")"

    restore_backup

    msg_info "Starting WireGuard Portal"
    systemctl start wgportal
    msg_ok "Started WireGuard Portal"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}Interfaces created in the UI listen from UDP port 51820.${CL}"
