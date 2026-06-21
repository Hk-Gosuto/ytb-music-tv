#!/bin/sh
set -eu

APP_UID="${YTB_MUSIC_TV_UID:-1000}"
APP_GID="${YTB_MUSIC_TV_GID:-1000}"
DATA_DIR="${YTB_MUSIC_TV_DATA_DIR:-/data}"

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$DATA_DIR"
  chown -R "$APP_UID:$APP_GID" "$DATA_DIR"
  exec gosu "$APP_UID:$APP_GID" "$@"
fi

exec "$@"
