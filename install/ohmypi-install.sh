#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/can1357/oh-my-pi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

ARCH=$(arch_resolve x64 arm64)
fetch_and_deploy_gh_release "ohmypi" "can1357/oh-my-pi" "singlefile" "latest" "/usr/local/bin" "omp-linux-${ARCH}"

motd_ssh
customize
cleanup_lxc
