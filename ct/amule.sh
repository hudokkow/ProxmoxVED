#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/amule-org/amule

APP="aMule"
var_tags="${var_tags:-ed2k;download;p2p}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/amule ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "amule" "amule-org/amule"; then
    msg_info "Stopping Service"
    systemctl stop amuled
    msg_ok "Stopped Service"

    create_backup /opt/amule/data

    msg_info "Updating aMule"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "amule" "amule-org/amule" "prebuild" "latest" "/opt/amule" "aMule-*-src.tar.gz"

    msg_info "Building aMule"
    cd /opt/amule
    rm -rf build
    mkdir -p build
    cd build
    $STD cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/amule \
      -DWX_GTK=3 \
      -DENABLE_AMULECMD=ON \
      -DENABLE_WEBSERVER=ON \
      -DENABLE_UPNP=ON \
      -DENABLE_IP2COUNTRY=ON
    $STD make -j "$(nproc)"
    $STD make install
    $STD ldconfig
    cd /opt/amule
    rm -rf build
    msg_ok "Built aMule"

    restore_backup

    msg_info "Starting Service"
    systemctl start amuled
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
echo -e "${INFO}${YW}Access the Web UI using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:4711${CL}"
