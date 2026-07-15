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

  ensure_dependencies jq
  LATEST=$(curl -s https://pypi.org/pypi/open-terminal/json | jq -r '.info.version')
  CURRENT=$(cat /opt/openterminal/version 2>/dev/null || echo "0")

  if [[ -z "${LATEST}" ]]; then
    msg_error "Failed to check for the latest version"
    exit
  fi

  if [[ "${LATEST}" == "${CURRENT}" ]]; then
    msg_ok "Already up to date (v${CURRENT})"
    exit
  fi

  msg_info "Updating ${APP} to v${LATEST}"
  systemctl stop openterminal

  msg_info "Backing up Configuration"
  cp /opt/openterminal/.env /opt/openterminal.env.bak
  msg_ok "Backed up Configuration"

  $STD /opt/openterminal/venv/bin/pip install --upgrade "open-terminal==${LATEST}"
  echo "${LATEST}" > /opt/openterminal/version

  msg_info "Restoring Configuration"
  cp /opt/openterminal.env.bak /opt/openterminal/.env
  rm -f /opt/openterminal.env.bak
  msg_ok "Restored Configuration"

  systemctl start openterminal
  msg_ok "Updated ${APP} to v${LATEST}"
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
