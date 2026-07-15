#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: h.udo (hudokkow)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/open-webui/open-terminal

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  cmake \
  git \
  pandoc \
  texlive-latex-base \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libgdk-pixbuf-2.0-0 \
  libcairo2
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
setup_ffmpeg
setup_imagemagick
PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Open Terminal (core)"
$STD uv venv --clear /opt/openterminal/venv
$STD uv pip install --python=/opt/openterminal/venv/bin/python open-terminal
msg_ok "Installed Open Terminal"

msg_info "Creating API Key"
API_KEY=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | cut -c1-32)
cat > /opt/openterminal/.env <<EOF
OPEN_TERMINAL_API_KEY=${API_KEY}
EOF
msg_ok "Created API Key"

msg_info "Creating Service"
cat > /etc/systemd/system/openterminal.service <<'EOF'
[Unit]
Description=Open Terminal Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openterminal
EnvironmentFile=/opt/openterminal/.env
ExecStart=/opt/openterminal/venv/bin/open-terminal run --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openterminal
msg_ok "Created Service"

msg_info "Installing data-science stack"
cat > /opt/openterminal/requirements.txt <<'EOF'
numpy
pandas
scipy
scikit-learn
matplotlib
seaborn
plotly
jupyter
ipython
requests
beautifulsoup4
lxml
sqlalchemy
psycopg2-binary
pyyaml
toml
jsonlines
tqdm
rich
openpyxl
weasyprint
python-docx
python-pptx
pypdf
csvkit
EOF
$STD uv pip install --python=/opt/openterminal/venv/bin/python -r /opt/openterminal/requirements.txt || true
msg_ok "Installed data-science stack"

msg_info "Storing Version"
uv pip show --python=/opt/openterminal/venv/bin/python open-terminal 2>/dev/null | awk -F': ' '/^Version/{print $2}' > /opt/openterminal/version
msg_ok "Stored Version"

motd_ssh
customize
cleanup_lxc
