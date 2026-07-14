#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/got3nks/amutorrent

APP="aMuTorrent"
var_tags="${var_tags:-download;torrent;manager}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/amutorrent ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "amutorrent" "got3nks/amutorrent"; then
    msg_info "Stopping Service"
    systemctl stop amutorrent
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/amutorrent/server/data /opt/amutorrent_data_backup
    cp -r /opt/amutorrent/server/logs /opt/amutorrent_logs_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "amutorrent" "got3nks/amutorrent" "tarball"

    msg_info "Building Frontend"
    cd /opt/amutorrent
    $STD npm install
    $STD npm run build
    msg_ok "Built Frontend"

    msg_info "Installing Server Dependencies"
    cd /opt/amutorrent/server
    $STD npm ci --omit=dev
    msg_ok "Installed Server Dependencies"

    msg_info "Restoring Data"
    cp -r /opt/amutorrent_data_backup/. /opt/amutorrent/server/data
    cp -r /opt/amutorrent_logs_backup/. /opt/amutorrent/server/logs
    rm -rf /opt/amutorrent_data_backup /opt/amutorrent_logs_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start amutorrent
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
echo -e "${GATEWAY}${BGN}http://${IP}:4000${CL}"
