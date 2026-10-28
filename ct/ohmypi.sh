#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/can1357/oh-my-pi

APP="Oh-My-Pi"
var_tags="${var_tags:-ai;coding;agent;cli}"
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

  if [[ ! -f /usr/local/bin/ohmypi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ohmypi" "can1357/oh-my-pi"; then
    msg_info "Stopping Service"
    systemctl stop ohmypi-ttyd
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "ohmypi" "can1357/oh-my-pi" "singlefile" "latest" "/usr/local/bin" "omp-linux-$(arch_resolve "x64" "arm64")"

    msg_info "Starting Service"
    systemctl start ohmypi-ttyd
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
echo -e "${INFO}${YW}Access Oh-My-Pi in your browser at http://${IP}${CL}"
echo -e "${INFO}${YW}Config and session data is stored in ~/.omp/.${CL}"
echo -e "${INFO}${YW}Documentation: https://omp.sh/docs${CL}"
