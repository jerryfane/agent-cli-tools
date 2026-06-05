#!/usr/bin/env bash
set -uo pipefail

failures=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'ok   %s\n' "$label"
  else
    printf 'fail %s\n' "$label"
    failures=$((failures + 1))
  fi
}

check "python3 on PATH" command -v python3
check "codex-usage-api on PATH" command -v codex-usage-api
check "codex-usage-all on PATH" command -v codex-usage-all
check "herdr-codex-usage-sidebar on PATH" command -v herdr-codex-usage-sidebar

if command -v codex-usage-api >/dev/null 2>&1; then
  echo "profiles:"
  codex-usage-api --profiles-json || failures=$((failures + 1))
  check "compact usage fetch runs" codex-usage-api --list-profiles
fi

if command -v systemctl >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    check "sidebar systemd service active" systemctl is-active --quiet herdr-codex-usage-sidebar.service
  else
    check "sidebar user service active" systemctl --user is-active --quiet herdr-codex-usage-sidebar.service
  fi
fi

if [ "$failures" -eq 0 ]; then
  echo "Doctor passed."
else
  echo "Doctor found $failures issue(s)."
fi

exit "$failures"
