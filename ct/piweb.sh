#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/jmfederico/pi-web

APP="Pi Web"
var_tags="${var_tags:-ai;coding-agent;web}"
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

  if [[ ! -d /opt/pi-web ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pi-web" "jmfederico/pi-web"; then
    msg_info "Stopping Services"
    systemctl stop pi-web pi-web-sessiond
    msg_ok "Stopped Services"

    create_backup /root/.config/pi-web /root/.pi /root/.pi-web

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pi-web" "jmfederico/pi-web" "tarball"

    msg_info "Building Pi Web"
    cd /opt/pi-web
    $STD npm install
    $STD npm run build
    msg_ok "Built Pi Web"

    for d in /root/.pi /root/.pi-web; do
      [ -f "$d" ] && rm -f "$d"
      mkdir -p "$d"
    done

    restore_backup

    msg_info "Starting Services"
    systemctl start pi-web-sessiond pi-web
    msg_ok "Started Services"
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
