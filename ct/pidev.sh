#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/earendil-works/pi

APP="pidev"
var_tags="${var_tags:-ai;coding-agent;llm}"
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

  if [[ ! -f /usr/local/bin/pi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pi" "earendil-works/pi"; then
    msg_info "Stopping Service"
    systemctl stop pi-ttyd
    msg_ok "Stopped Service"

    create_backup /opt/pidev/data /opt/pidev/pi.env

    ARCH=$(uname -m)
    case "$ARCH" in
    x86_64) AMI_ARCH="x64" ;;
    aarch64) AMI_ARCH="arm64" ;;
    *)
      msg_error "Unsupported architecture: $ARCH"
      exit 1
      ;;
    esac

    msg_info "Updating pidev"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pidev" "earendil-works/pi" "prebuild" "latest" "/opt/pidev" "pi-linux-${AMI_ARCH}.tar.gz"
    ln -sf /opt/pidev/pi /usr/local/bin/pi
    msg_ok "Updated pidev"

    restore_backup

    msg_info "Starting Service"
    systemctl start pi-ttyd
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
echo -e "${GATEWAY}${BGN}http://${IP}:7681${CL}"
echo -e "${INFO}${YW}Install extensions at runtime, e.g.:${CL}"
echo -e "${GATEWAY}${BGN}pi install npm:context-mode${CL}"
