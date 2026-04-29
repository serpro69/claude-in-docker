#!/bin/sh
set -e

# If HOST_UID is provided, remap the node user to match host UID/GID.
# This ensures bind-mounted files from the host are accessible inside the container.
if [ -n "$HOST_UID" ]; then
  CUR_UID=$(id -u node)
  CUR_GID=$(id -g node)
  NEW_GID="${HOST_GID:-$HOST_UID}"

  if [ "$CUR_GID" != "$NEW_GID" ]; then
    groupmod -o -g "$NEW_GID" node
  fi
  if [ "$CUR_UID" != "$HOST_UID" ]; then
    usermod -o -u "$HOST_UID" node
  fi

  # Fix ownership of node's directories inside the container
  chown -R node:node /home/node /commandhistory /usr/local/share/npm-global
fi

# Fix host/container home-directory path mismatch for plugin JSON files.
# When ~/.claude is bind-mounted from a host with a different home path
# (e.g. /Users/sergio vs /home/node), Claude Code rejects plugin paths.
# We copy each JSON file to /tmp, rewrite paths, and bind-mount it over
# the original — host files are never modified.
# Requires --cap-add=SYS_ADMIN for the bind mount.
CONTAINER_HOME=$(eval echo "~node")
PLUGINS_DIR="$CONTAINER_HOME/.claude/plugins"
if [ -d "$PLUGINS_DIR" ]; then
  # Detect host home from paths in plugin JSON files
  HOST_HOME=""
  for f in "$PLUGINS_DIR"/known_marketplaces.json "$PLUGINS_DIR"/installed_plugins.json; do
    [ -f "$f" ] || continue
    HOST_HOME=$(jq -r '
      .. | objects | .installLocation // .installPath // empty
    ' "$f" 2>/dev/null | head -1 | sed -n 's|\(.*\)/\.claude/.*|\1|p')
    [ -n "$HOST_HOME" ] && break
  done

  if [ -n "$HOST_HOME" ] && [ "$HOST_HOME" != "$CONTAINER_HOME" ]; then
    REWRITE_OK=false
    for f in "$PLUGINS_DIR"/known_marketplaces.json "$PLUGINS_DIR"/installed_plugins.json; do
      [ -f "$f" ] || continue
      tmp="/tmp/claude-plugins-$(basename "$f")"
      cp -p "$f" "$tmp"
      sed -i "s|$HOST_HOME|$CONTAINER_HOME|g" "$tmp"
      chown node:node "$tmp"
      if mount --bind "$tmp" "$f" 2>/dev/null; then
        REWRITE_OK=true
      fi
    done

    if [ "$REWRITE_OK" = false ]; then
      echo "WARNING: Plugin marketplace paths reference host home ($HOST_HOME) which differs from" >&2
      echo "  container home ($CONTAINER_HOME). Plugins may not work correctly." >&2
      echo "  To fix, run the container with --cap-add=SYS_ADMIN." >&2
    fi
  fi
fi

# Activate firewall on firewalled image variants before dropping to unprivileged user.
# Set DISABLE_FIREWALL=1 to skip (e.g. for debugging network issues).
if [ -f /etc/cind-firewalled ] && [ "${DISABLE_FIREWALL:-0}" != "1" ]; then
  echo "Activating firewall (firewalled image detected)..."
  if ! /usr/local/bin/init-firewall.sh; then
    echo "ERROR: Firewall activation failed." >&2
    echo "  The firewalled image requires: --cap-add=NET_ADMIN" >&2
    exit 1
  fi
fi

exec gosu node "$@"
