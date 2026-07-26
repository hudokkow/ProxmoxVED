#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/MoonshotAI/kimi-cli

APP="Kimi CLI"
var_tags="${var_tags:-ai;cli;terminal}"
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

  if [[ ! -f /usr/local/bin/kimi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "kimi-cli" "MoonshotAI/kimi-cli"; then
    msg_info "Stopping Service"
    systemctl stop kimi-cli
    msg_ok "Stopped Service"

    ARCH=$(arch_resolve x86_64 aarch64)
    fetch_and_deploy_gh_release "kimi-cli" "MoonshotAI/kimi-cli" "prebuild" "latest" "/usr/local/bin" "kimi-*-${ARCH}-unknown-linux-gnu.tar.gz"

    TTYD_ARCH=$(arch_resolve x86_64 aarch64)
    fetch_and_deploy_gh_release "ttyd" "tsl0922/ttyd" "singlefile" "latest" "/usr/local/bin" "ttyd.${TTYD_ARCH}"

    msg_info "Starting Service"
    systemctl start kimi-cli
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