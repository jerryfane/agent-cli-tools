# Agent CLI Tools

Small terminal tools for managing AI coding-agent workflows.

Current tools:

- `codex-usage-api`: fetch Codex subscription quota for one or more local Codex profiles.
- `codex-usage-all`: human-readable multi-profile Codex usage view.
- `herdr-codex-usage-sidebar`: publish compact Codex quota labels into Herdr panes.
- `codex-profile`: create, inspect, and repair local multi-sub Codex profile homes.

## What This Tracks

This is Codex-only for now. It reads each profile's local Codex `auth.json` and calls the ChatGPT/Codex usage endpoint to fetch remaining 5-hour and weekly quota.

It does not start a Codex session, does not send prompts to a model, and should not consume Codex model tokens.

The usage endpoint is an internal ChatGPT/Codex backend endpoint used by Codex-related tooling. It may change.

## Install

```bash
git clone https://github.com/jerryfane/agent-cli-tools.git
cd agent-cli-tools
./install.sh
./doctor.sh
```

By default, profiles are auto-discovered from `~/.codex-*` directories that contain `auth.json`. If no profile directories are found, it falls back to `~/.codex`.

For explicit profile names:

```bash
export CODEX_USAGE_PROFILES="work=$HOME/.codex-work,personal=$HOME/.codex-personal"
export CODEX_USAGE_LABEL_PREFIXES="work=w,personal=p"
export CODEX_USAGE_DEFAULT_PROFILE="work"
./install.sh
```

## Commands

Create a new Codex profile for another subscription:

```bash
codex-profile create spark
codex-spark login
codex-profile doctor spark
codex-spark resume <session-id> --yolo
```

The profile layout keeps auth and local state private, while sharing sessions, goals, skills, and plugins with the base Codex home.
When another local profile already has a complete Codex session index, `codex-profile create` seeds the new profile from it to avoid the first-run backfill timeout.

Repair a profile after Codex's own repair flow or a manual setup mistake:

```bash
codex-profile repair spark
codex-profile doctor spark
```

This specifically checks for the dangerous mixed SQLite layout where `goals_1.sqlite` is private but `goals_1.sqlite-wal` and `goals_1.sqlite-shm` still point to the shared base DB.
It also repairs a stuck `state_5.sqlite` backfill by seeding from a healthy sibling profile when one exists.

Full usage view:

```bash
codex-usage-all
```

Compact one-profile view:

```bash
codex-usage-api --compact-profile work
```

JSON:

```bash
codex-usage-api --json
```

Force a fresh network refresh:

```bash
codex-usage-api --force-refresh
```

## Configuration

Environment variables:

- `CODEX_USAGE_PROFILES`: comma-separated `name=/path` entries.
- `CODEX_USAGE_LABEL_PREFIXES`: comma-separated `name=label` entries for Herdr sidebar labels.
- `CODEX_USAGE_DEFAULT_PROFILE`: profile used for unlabeled Codex panes.
- `CODEX_USAGE_CACHE_DIR`: cache directory, default `~/.cache/codex-usage`.
- `CODEX_USAGE_URL`: override usage endpoint, default `https://chatgpt.com/backend-api/wham/usage`.
- `CODEX_PROFILE_BASE_HOME`: base Codex home for `codex-profile`, default `~/.codex`.
- `CODEX_PROFILE_BIN_DIR`: wrapper install directory for `codex-profile`, default `~/.local/bin`.

Cache files are written with private permissions. The usage cache does not contain access tokens or refresh tokens. If an access token must be refreshed, the refreshed token is cached separately under the same private cache directory.

## Herdr Sidebar

The installer enables `herdr-codex-usage-sidebar.service` when systemd is available. The service refreshes Herdr metadata every 30 seconds, while the quota API fetch is cached for 5 minutes by default.

Restart after changing environment variables:

```bash
sudo systemctl restart herdr-codex-usage-sidebar.service
```

For user-level installs:

```bash
systemctl --user restart herdr-codex-usage-sidebar.service
```

## Notes

- Do not commit `auth.json`, token cache files, or usage cache files.
- If a profile reports an auth error, run Codex with that profile and log in again.
- The first start of a new profile may take time while Codex indexes the shared sessions directory.
- Claude Code is not supported yet, but a similar approach could be added with a separate parser/fetcher.
