#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${INSTALL_BIN_DIR:-$HOME/.local/bin}"
service_name="herdr-codex-usage-sidebar.service"

install -d "$bin_dir"
install -m 0755 "$repo_dir/bin/codex-profile" "$bin_dir/codex-profile"
install -m 0755 "$repo_dir/bin/codex-usage-api" "$bin_dir/codex-usage-api"
install -m 0755 "$repo_dir/bin/codex-usage-all" "$bin_dir/codex-usage-all"
install -m 0755 "$repo_dir/bin/herdr-codex-usage-sidebar" "$bin_dir/herdr-codex-usage-sidebar"

env_line() {
  local key="$1"
  local value="${!key:-}"
  if [ -n "$value" ]; then
    printf 'Environment=%s=%s\n' "$key" "$value"
  fi
}

render_system_service() {
  cat <<EOF
[Unit]
Description=Publish compact Codex usage into Herdr sidebar metadata
After=herdr-default.service
Wants=herdr-default.service

[Service]
Type=simple
User=$(id -un)
WorkingDirectory=$HOME
Environment=HOME=$HOME
Environment=PATH=$bin_dir:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
$(env_line CODEX_USAGE_PROFILES)
$(env_line CODEX_USAGE_LABEL_PREFIXES)
$(env_line CODEX_USAGE_DEFAULT_PROFILE)
$(env_line CODEX_USAGE_CACHE_DIR)
ExecStart=$bin_dir/herdr-codex-usage-sidebar 30
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

render_user_service() {
  cat <<EOF
[Unit]
Description=Publish compact Codex usage into Herdr sidebar metadata

[Service]
Type=simple
WorkingDirectory=$HOME
Environment=HOME=$HOME
Environment=PATH=$bin_dir:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
$(env_line CODEX_USAGE_PROFILES)
$(env_line CODEX_USAGE_LABEL_PREFIXES)
$(env_line CODEX_USAGE_DEFAULT_PROFILE)
$(env_line CODEX_USAGE_CACHE_DIR)
ExecStart=$bin_dir/herdr-codex-usage-sidebar 30
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
}

if [ "${INSTALL_SYSTEMD:-1}" = "1" ] && command -v systemctl >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    render_system_service >"/etc/systemd/system/$service_name"
    systemctl daemon-reload
    systemctl enable "$service_name"
    systemctl restart "$service_name"
  else
    user_systemd="$HOME/.config/systemd/user"
    install -d "$user_systemd"
    render_user_service >"$user_systemd/$service_name"
    systemctl --user daemon-reload
    systemctl --user enable "$service_name"
    systemctl --user restart "$service_name"
  fi
else
  echo "Installed scripts only. Set INSTALL_SYSTEMD=1 and rerun to install the sidebar service." >&2
fi

echo "Installed agent CLI tools."
echo "Scripts: $bin_dir"
echo "Profiles:"
"$bin_dir/codex-usage-api" --profiles-json || true
