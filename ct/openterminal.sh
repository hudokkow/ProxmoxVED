#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/open-webui/open-terminal

APP="Open Terminal"
var_tags="${var_tags:-ai;terminal;devtools}"
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

  if [[ ! -d /opt/openterminal ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "openterminal" "open-webui/open-terminal"; then
    msg_info "Stopping Service"
    systemctl stop openterminal
    msg_ok "Stopped Service"

    create_backup /opt/openterminal/.env

    msg_info "Updating Open Terminal"
    $STD uv pip install --python=/opt/openterminal/venv/bin/python --upgrade open-terminal
    msg_info "Storing Version"
    uv pip show --python=/opt/openterminal/venv/bin/python open-terminal 2>/dev/null | grep '^Version:' | cut -d: -f2- | tr -d ' ' > ~/.openterminal
    msg_ok "Stored Version"
    msg_ok "Updated Open Terminal"

    restore_backup

    msg_info "Starting Service"
    systemctl start openterminal
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW}API key is stored in /opt/openterminal/.env (OPEN_TERMINAL_API_KEY).${CL}"
