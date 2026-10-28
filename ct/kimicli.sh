#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/MoonshotAI/kimi-code

APP="Kimi Code"
var_tags="${var_tags:-ai;cli;terminal;coding-agent}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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

  if [[ ! -f /opt/kimicli/apps/kimi-code/dist/main.mjs ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_branch "kimicli" "MoonshotAI/kimi-code" "main"; then
    msg_info "Stopping Service"
    systemctl stop kimicli
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.$(arch_resolve "x86_64" "aarch64")"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_branch "kimicli" "MoonshotAI/kimi-code" "main" "/opt/kimicli"

    msg_info "Installing Dependencies"
    cd /opt/kimicli
    $STD pnpm install
    msg_ok "Installed Dependencies"

    msg_info "Building Kimi Code"
    $STD pnpm run build
    msg_ok "Built Kimi Code"

    ln -sf /opt/kimicli/apps/kimi-code/dist/main.mjs /usr/local/bin/kimi
    msg_ok "Linked binary"

    msg_info "Starting Service"
    systemctl start kimicli
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
