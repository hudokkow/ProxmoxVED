#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
# Engine comes from community-scripts/core; this repo only ships the scripts.
# A local core checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core),
# so a fork or branch of core can be tested without editing this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/anomalyco/opencode

APP="OpenCode"
var_tags="${var_tags:-ai;coding;cli}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/opencode/opencode ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "opencode" "anomalyco/opencode"; then
    msg_info "Stopping Service"
    systemctl stop opencode
    msg_ok "Stopped Service"

    create_backup /etc/systemd/system/opencode.service /opt/opencode/.config /opt/opencode/.env

    ARCH=$(arch_resolve x64 arm64)
    fetch_and_deploy_gh_release "opencode" "anomalyco/opencode" "prebuild" "latest" "/opt/opencode" "opencode-linux-${ARCH}.tar.gz"

    restore_backup

    msg_info "Starting Service"
    systemctl start opencode
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
echo -e "${INFO}${YW}Access OpenCode in your browser at:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}User is ${BGN}opencode${CL}"
echo -e "${INFO}${YW}Password is stored in ${BGN}/opt/opencode/.env${CL}"
