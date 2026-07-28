#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/NousResearch/hermes-agent

APP="HermesWebUI"
var_tags="${var_tags:-ai;coding-agent;webui;terminal}"
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

  if [[ ! -d /opt/hermeswebui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "hermeswebui" "nesquena/hermes-webui"; then
    msg_info "Stopping Service"
    systemctl stop hermeswebui
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    create_backup /root/.hermes
    msg_ok "Backed up Data"

    msg_info "Updating Hermes Agent"
    $STD uv pip install --python /opt/hermesagent --upgrade hermes-agent
    msg_ok "Updated Hermes Agent"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "hermeswebui" "nesquena/hermes-webui" "tarball" "latest" "/opt/hermeswebui"

    msg_info "Updating WebUI Dependencies"
    $STD uv pip install --python /opt/hermesagent -r /opt/hermeswebui/requirements.txt
    msg_ok "Updated WebUI Dependencies"

    msg_info "Restoring Data"
    restore_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start hermeswebui
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