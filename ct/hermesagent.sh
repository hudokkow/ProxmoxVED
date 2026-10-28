#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/NousResearch/hermes-agent

APP="Hermes Agent"
var_tags="${var_tags:-ai;coding-agent;cli;terminal}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -f /opt/hermesagent/bin/hermes ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ttyd" "tsl0922/ttyd"; then
    msg_info "Stopping Service"
    systemctl stop hermesagent
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.$(arch_resolve "x86_64" "aarch64")"

    msg_info "Updating Hermes Agent"
    $STD uv pip install --python /opt/hermesagent --upgrade hermes-agent
    msg_ok "Updated Hermes Agent"

    msg_info "Starting Service"
    systemctl start hermesagent
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
