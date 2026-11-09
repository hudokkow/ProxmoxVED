source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_tag "deepseekharness" "deepseek-ai/deepseek-harness"

NODE_VERSION="24" NODE_MODULE="pnpm@$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/deepseekharness/package.json)" setup_nodejs

msg_info "Building Application"
cd /opt/deepseekharness
$STD pnpm install
$STD pnpm run build
msg_ok "Built Application"

msg_info "Creating Configuration"
cat <<EOF >/opt/deepseekharness/.env
NODE_ENV=production
DSH_WEB_HOST=${LOCAL_IP}
EOF
msg_ok "Created Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/deepseekharness.service
[Unit]
Description=DeepSeekHarness Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/deepseekharness
EnvironmentFile=/opt/deepseekharness/.env
ExecStart=/usr/bin/pnpm dsh web --no-open --host ${DSH_WEB_HOST} --port 80
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now deepseekharness
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
