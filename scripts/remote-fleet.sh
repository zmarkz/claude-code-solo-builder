#!/usr/bin/env bash
# remote-fleet.sh — keep Claude Code Remote Control servers running for a list of
# repos, so any of them can be driven from the Claude app or claude.ai/code.
#
#   remote-fleet.sh install     write the Terminal launcher + launchd watchdog, start
#   remote-fleet.sh uninstall   stop everything and remove the watchdog
#   remote-fleet.sh status      one line per server
#   remote-fleet.sh restart     stop the servers; the supervisor brings them back
#   remote-fleet.sh supervise   (internal) the restart loop, runs inside Terminal
#   remote-fleet.sh watchdog    (internal) launchd tick
#
# Config: ~/.claude/remote-fleet.conf (shell-sourced). See docs/REMOTE-OPS.md.
#
# Why servers run under Terminal instead of directly under launchd: macOS privacy
# controls refuse launchd jobs access to ~/Documents, ~/Desktop and ~/Downloads
# unless they hold Full Disk Access, so a launchd-hosted server cannot work in repos
# there and fails with "Operation not permitted". launchd therefore only runs the
# watchdog, which re-opens the Terminal-hosted supervisor if it has gone away.
#
# Why a supervisor at all: a server gives up and exits after ~10 minutes without
# network, so a home outage would otherwise take remote access down for good.
set -u

DEST="${CLAUDE_HOME:-$HOME/.claude}"
CONF="${REMOTE_FLEET_CONF:-$DEST/remote-fleet.conf}"
STATE="$DEST/remote-fleet"
LABEL="com.solo-builder.remote-fleet"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SELF="$DEST/scripts/remote-fleet.sh"
TAILSCALE_APP="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Defaults. Override in the config file.
FLEET_PERMISSION_MODE="default"   # default | acceptEdits | auto | bypassPermissions
FLEET_CHROME=0                    # 1 = spawned sessions may drive Chrome on this machine
FLEET_CAPACITY=8                  # max concurrent sessions per server
FLEET_KEEP_AWAKE=1                # 1 = hold the machine and display awake while supervising
FLEET_KEEP_CHROME=0               # 1 = watchdog reopens Chrome if it was quit
FLEET_KEEP_TAILSCALE=0            # 1 = watchdog reconnects Tailscale if it was stopped

NAMES=(); PATHS=(); SPAWNS=()
repo() { PATHS+=("$1"); NAMES+=("$2"); SPAWNS+=("${3:-worktree}"); }

load_conf() {
  if [ ! -f "$CONF" ]; then echo "remote-fleet: no config at $CONF (see docs/REMOTE-OPS.md)" >&2; return 1; fi
  # shellcheck disable=SC1090
  . "$CONF"
  mkdir -p "$STATE/logs" "$STATE/pids"
}

alive() { [ -f "$1" ] && kill -0 "$(cat "$1" 2>/dev/null)" 2>/dev/null; }

# Remote Control refuses a folder until a person has accepted its trust prompt.
needs_trust() { tail -c 400 "$STATE/logs/$1.log" 2>/dev/null | grep -aq "not trusted"; }

start_server() {
  local path="$1" name="$2" spawn="$3" log="$STATE/logs/$2.log" chrome="--no-chrome"
  [ "$FLEET_CHROME" = "1" ] && chrome="--chrome"
  [ -d "$path" ] || { echo "$(date '+%F %T') skip $name: missing $path" >> "$STATE/logs/supervisor.log"; return 0; }
  # Spinner redraws make these logs grow; they are only useful for the latest run.
  [ -f "$log" ] && [ "$(wc -c < "$log")" -gt 5242880 ] && : > "$log"
  (
    cd "$path" || exit 1
    nohup claude remote-control --name "$name" --spawn "$spawn" --capacity "$FLEET_CAPACITY" \
      --permission-mode "$FLEET_PERMISSION_MODE" "$chrome" --no-create-session-in-dir \
      </dev/null >>"$log" 2>&1 &
    echo $! > "$STATE/pids/$name.pid"
  )
  date +%s > "$STATE/pids/$name.started"
  echo "$(date '+%F %T') started $name ($spawn) in $path" >> "$STATE/logs/supervisor.log"
}

supervise() {
  load_conf || exit 1
  if alive "$STATE/pids/supervisor.pid"; then
    echo "remote-fleet: supervisor already running"; exit 0
  fi
  echo $$ > "$STATE/pids/supervisor.pid"
  if [ "$FLEET_KEEP_AWAKE" = "1" ]; then caffeinate -dims -w $$ & fi
  echo "remote-fleet supervising ${#NAMES[@]} servers. Leave this window open. Logs: $STATE/logs"
  while :; do
    local i now started wait
    now=$(date +%s)
    for i in "${!NAMES[@]}"; do
      alive "$STATE/pids/${NAMES[$i]}.pid" && continue
      # Back off after a quick death so a bad repo cannot spin. An untrusted folder
      # gets a slow retry, so it comes online by itself once the prompt is accepted.
      started=$(cat "$STATE/pids/${NAMES[$i]}.started" 2>/dev/null || echo 0)
      wait=60; needs_trust "${NAMES[$i]}" && wait=600
      [ $((now - started)) -lt "$wait" ] && continue
      start_server "${PATHS[$i]}" "${NAMES[$i]}" "${SPAWNS[$i]}"
    done
    /bin/sleep 20
  done
}

watchdog() {
  load_conf || exit 0
  alive "$STATE/pids/supervisor.pid" || /usr/bin/open -g -a Terminal "$STATE/fleet.command"
  if [ "$FLEET_KEEP_CHROME" = "1" ] && ! /usr/bin/pgrep -xq "Google Chrome"; then
    /usr/bin/open -g -a "Google Chrome"
  fi
  if [ "$FLEET_KEEP_TAILSCALE" = "1" ] && [ -x "$TAILSCALE_APP" ]; then
    "$TAILSCALE_APP" status 2>&1 | grep -qi "stopped" && "$TAILSCALE_APP" up >/dev/null 2>&1
  fi
  return 0
}

status() {
  load_conf || exit 1
  if alive "$STATE/pids/supervisor.pid"; then echo "supervisor: up (pid $(cat "$STATE/pids/supervisor.pid"))"; else echo "supervisor: DOWN"; fi
  launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1 && echo "watchdog:   loaded" || echo "watchdog:   NOT loaded"
  local i pid log env state
  for i in "${!NAMES[@]}"; do
    pid=$(cat "$STATE/pids/${NAMES[$i]}.pid" 2>/dev/null || echo -)
    log="$STATE/logs/${NAMES[$i]}.log"
    state=DOWN; needs_trust "${NAMES[$i]}" && state=needs-trust
    alive "$STATE/pids/${NAMES[$i]}.pid" && state=up
    env=$(grep -ao 'environment=env_[A-Za-z0-9]*' "$log" 2>/dev/null | tail -1 | cut -d= -f2)
    printf '%-21s %-11s pid=%-7s %-9s %s\n' "${NAMES[$i]}" "$state" "$pid" "${SPAWNS[$i]}" "${env:-no-environment-yet}"
  done
}

stop_servers() {
  load_conf || return 1
  local i
  for i in "${!NAMES[@]}"; do
    alive "$STATE/pids/${NAMES[$i]}.pid" && kill "$(cat "$STATE/pids/${NAMES[$i]}.pid")" 2>/dev/null
    rm -f "$STATE/pids/${NAMES[$i]}.pid" "$STATE/pids/${NAMES[$i]}.started"
  done
}

install_fleet() {
  load_conf || exit 1
  [ -x "$SELF" ] || { echo "remote-fleet: run ./install.sh first ($SELF missing)" >&2; exit 1; }
  # A login shell so servers inherit the same PATH (nvm, Homebrew) as an interactive terminal.
  cat > "$STATE/fleet.command" <<CMD
#!/bin/zsh -l
exec bash "$SELF" supervise
CMD
  chmod +x "$STATE/fleet.command"
  mkdir -p "$(dirname "$PLIST")"
  cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$SELF</string><string>watchdog</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>300</integer>
  <key>StandardErrorPath</key><string>$STATE/logs/watchdog.log</string>
  <key>StandardOutPath</key><string>$STATE/logs/watchdog.log</string>
</dict></plist>
PL
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  echo "remote-fleet installed: watchdog every 5 min; supervisor opens in Terminal."
}

uninstall_fleet() {
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
  rm -f "$PLIST"
  alive "$STATE/pids/supervisor.pid" && kill "$(cat "$STATE/pids/supervisor.pid")" 2>/dev/null
  rm -f "$STATE/pids/supervisor.pid"
  stop_servers
  echo "remote-fleet removed. Config kept at $CONF."
}

case "${1:-status}" in
  install)   install_fleet ;;
  uninstall) uninstall_fleet ;;
  status)    status ;;
  restart)   stop_servers; echo "servers stopped; the supervisor restarts them within a minute" ;;
  supervise) supervise ;;
  watchdog)  watchdog ;;
  *) sed -n '2,11p' "$0"; exit 2 ;;
esac
