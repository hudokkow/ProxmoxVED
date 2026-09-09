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
# Source: https://github.com/deepseek-ai/deepseek-harness

APP="DeepSeekHarness"
var_tags="${var_tags:-ai;agent;coding;dev-tools}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/deepseekharness ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  if GH_INCLUDE_PRERELEASE=1 check_for_gh_release "deepseekharness" "deepseek-ai/deepseek-harness"; then
    msg_info "Stopping Service"
    systemctl stop deepseekharness
    msg_ok "Stopped Service"

    if [[ -d /opt/deepseekharness/.dsh ]]; then
      create_backup /opt/deepseekharness/.dsh
    fi

    GH_INCLUDE_PRERELEASE=1 CLEAN_INSTALL=1 fetch_and_deploy_gh_release "deepseekharness" "deepseek-ai/deepseek-harness" "tarball"

    if [[ -e /opt/deepseekharness.backup ]]; then
      restore_backup
    fi

    cd /opt/deepseekharness
    $STD npm install -g pnpm
    $STD pnpm install
    $STD pnpm run build

    msg_info "Starting Service"
    systemctl start deepseekharness
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
echo -e "${GATEWAY}${BGN}http://${IP}:3080${CL}"