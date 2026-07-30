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
# Source: https://github.com/itayinbarr/little-coder

APP="littlecoder"
var_tags="${var_tags:-ai;coding-agent;llm;cli}"
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

  if [[ ! -f /usr/local/bin/little-coder ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "littlecoder" "itayinbarr/little-coder"; then
    msg_info "Stopping Service"
    systemctl stop littlecoder-ttyd
    msg_ok "Stopped Service"

    msg_info "Updating Application"
    $STD npm install -g little-coder
    msg_ok "Updated Application"

    msg_info "Storing Version"
    npm list -g little-coder --depth=0 2>/dev/null | grep 'little-coder' | awk -F'@' '{print $NF}' | tr -d ' ' > ~/.littlecoder
    msg_ok "Stored Version"

    msg_info "Starting Service"
    systemctl start littlecoder-ttyd
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
echo -e "${INFO}${YW}Access the coding agent in your browser using:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"