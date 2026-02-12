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

exec gosu node "$@"
