#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/crazy-max/geoip-updater

APP="geoip-updater"
var_tags="${var_tags:-geoip;maxmind;network}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /usr/local/bin/geoip-updater ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "geoip-updater" "crazy-max/geoip-updater"; then
    msg_info "Stopping Service"
    systemctl stop geoip-updater
    msg_ok "Stopped Service"

    create_backup /opt/geoip-updater/data

    msg_info "Updating geoip-updater"
    ARCH=$(uname -m)
    case "$ARCH" in
    x86_64) AMI_ARCH="amd64" ;;
    aarch64) AMI_ARCH="arm64" ;;
    *)
      msg_error "Unsupported architecture: $ARCH"
      exit 1
      ;;
    esac
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "geoip-updater" "crazy-max/geoip-updater" "prebuild" "latest" "/opt/geoip-updater" "geoip-updater_*_linux_${AMI_ARCH}.tar.gz"
    ln -sf /opt/geoip-updater/geoip-updater /usr/local/bin/geoip-updater
    msg_ok "Updated geoip-updater"

    restore_backup

    msg_info "Starting Service"
    systemctl start geoip-updater
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
echo -e "${INFO}${YW}Databases are updated on the schedule defined in:${CL}"
echo -e "${GATEWAY}${BGN}/etc/geoip-updater/geoip-updater.env${CL}"
