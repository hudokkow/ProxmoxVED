#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../misc/build.func" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/Swetrix/swetrix

APP="Swetrix"
var_tags="${var_tags:-analytics;privacy;dashboard}"
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

  if [[ ! -d /opt/swetrix ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "swetrix" "Swetrix/swetrix" "" "" "v"; then
    msg_info "Stopping Service"
    systemctl stop swetrix-web swetrix-api
    msg_ok "Stopped Service"

    create_backup /opt/swetrix/backend/.env /opt/swetrix/web/.env /opt/swetrix/backend/ip-geolocation-db.mmdb

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "swetrix" "Swetrix/swetrix" "tarball" "latest" "/opt/swetrix" "" "v"

    restore_backup

    msg_info "Configuring Credentials"
    if grep -q '^requirepass' /etc/redis/redis.conf; then
      REDIS_PASSWORD=$(grep '^requirepass' /etc/redis/redis.conf | awk '{print $2}')
    else
      REDIS_PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
      cat <<EOF >>/etc/redis/redis.conf
requirepass ${REDIS_PASSWORD}
EOF
      systemctl restart redis-server
    fi

    if [[ -f /etc/clickhouse-server/users.d/password.xml ]]; then
      CLICKHOUSE_PASSWORD=$(sed -n 's:.*<password>\(.*\)</password>.*:\1:p' /etc/clickhouse-server/users.d/password.xml)
    else
      CLICKHOUSE_PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
      cat <<EOF >/etc/clickhouse-server/users.d/password.xml
<clickhouse>
  <users>
    <default>
      <password>${CLICKHOUSE_PASSWORD}</password>
    </default>
  </users>
</clickhouse>
EOF
      systemctl restart clickhouse-server
    fi

    sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASSWORD}|" /opt/swetrix/backend/.env
    sed -i "s|^CLICKHOUSE_PASSWORD=.*|CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}|" /opt/swetrix/backend/.env
    msg_ok "Configured Credentials"

    msg_info "Building API"
    cd /opt/swetrix/backend
    $STD npm ci --force
    $STD npm run deploy:community
    $STD node ./meta/dbip-free-sync.js
    msg_ok "Built API"

    msg_info "Building Web"
    cd /opt/swetrix/web
    $STD npm ci
    $STD npm run build
    msg_ok "Built Web"

    msg_info "Initializing ClickHouse"
    cd /opt/swetrix/backend
    $STD npm run clickhouse:initialise
    msg_ok "Initialized ClickHouse"

    msg_info "Configuring ClickHouse"
    cat <<EOF >/etc/clickhouse-server/users.d/async-insert.xml
<clickhouse>
  <profiles>
    <default>
      <async_insert>0</async_insert>
    </default>
  </profiles>
</clickhouse>
EOF
    $STD systemctl restart clickhouse-server
    msg_ok "Configured ClickHouse"

    msg_info "Starting Service"
    systemctl start swetrix-api swetrix-web
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
echo -e "${INFO}${YW}Access Swetrix in your browser at:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}Create your account through the onboarding flow on first access.${CL}"
