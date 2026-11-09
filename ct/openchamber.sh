#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/openchamber/openchamber

APP="OpenChamber"
var_tags="${var_tags:-ai;coding-agent;web-ui}"
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

  if [[ ! -f /usr/local/bin/opencode ]] || [[ ! -f /usr/bin/openchamber ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Services"
  systemctl stop openchamber opencode
  msg_ok "Stopped Services"

  fetch_and_deploy_gh_release "opencode" "anomalyco/opencode" "prebuild" "latest" "/usr/local/bin" "opencode-linux-$(arch_resolve "x64" "arm64").tar.gz"

  msg_info "Updating OpenChamber"
  NODE_VERSION="24" setup_nodejs
  $STD npm install -g @openchamber/web@latest
  msg_ok "Updated OpenChamber"

  msg_info "Starting Services"
  systemctl start opencode openchamber
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
