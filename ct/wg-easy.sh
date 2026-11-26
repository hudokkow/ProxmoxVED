#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/wg-easy/wg-easy

APP="wg-easy"
var_tags="${var_tags:-vpn;network;wireguard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/wgeasy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wgeasy" "wg-easy/wg-easy"; then
    msg_info "Stopping wg-easy"
    systemctl stop wgeasy
    msg_ok "Stopped wg-easy"

    create_backup /opt/wgeasy/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wgeasy" "wg-easy/wg-easy" "tarball"

    restore_backup

    PNPM_VERSION=$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/wgeasy/package.json)
    NODE_VERSION="24" NODE_MODULE="pnpm@${PNPM_VERSION:-12.21.0}" setup_nodejs

    msg_info "Building wg-easy"
    cd /opt/wgeasy/src
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    cp -a .output/. /opt/wgeasy/
    mkdir -p /opt/wgeasy/server/database/migrations
    cp server/database/migrations/*.sql /opt/wgeasy/server/database/migrations/
    rm -rf /opt/wgeasy/src/node_modules /opt/wgeasy/src/.output /opt/wgeasy/src/.nuxt
    msg_ok "Built wg-easy"

    msg_info "Starting wg-easy"
    systemctl start wgeasy
    msg_ok "Started wg-easy"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}WireGuard clients connect on UDP port 51820.${CL}"
