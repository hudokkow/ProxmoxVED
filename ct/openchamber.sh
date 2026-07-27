#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
# Engine comes from community-scripts/core; this repo only ships the scripts.
# A local core checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core),
# so a fork or branch of core can be tested without editing this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/openchamber/openchamber

APP="OpenChamber"
var_tags="${var_tags:-ai;coding-agent;web-ui}"
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

  if [[ ! -f /usr/local/bin/opencode ]] || [[ ! -f /usr/bin/openchamber ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "openchamber" "openchamber/openchamber"; then
    msg_info "Stopping Services"
    systemctl stop openchamber opencode
    msg_ok "Stopped Services"

    msg_info "Backing up Configuration"
    create_backup /opt/opencode/.env /opt/openchamber/.env
    msg_ok "Backed up Configuration"

    ARCH=$(arch_resolve x64 arm64)
    fetch_and_deploy_gh_release "opencode" "anomalyco/opencode" "prebuild" "latest" "/usr/local/bin" "opencode-linux-${ARCH}.tar.gz"

    msg_info "Updating OpenChamber"
    $STD npm install -g @openchamber/web@latest
    msg_ok "Updated OpenChamber"

    msg_info "Storing Version"
    npm list -g @openchamber/web --depth=0 2>/dev/null | grep '@openchamber/web' | awk -F'@' '{print $NF}' | tr -d ' ' > ~/.openchamber
    msg_ok "Stored Version"

    restore_backup

    msg_info "Starting Services"
    systemctl start opencode openchamber
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
echo -e "${INFO}${YW}Passwords are stored in ${BGN}/opt/openchamber/.env${CL} and ${BGN}/opt/opencode/.env${CL}"
