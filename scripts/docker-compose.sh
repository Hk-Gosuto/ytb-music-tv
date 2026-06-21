#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(dirname "$SCRIPT_DIR")

export YTB_MUSIC_TV_UID="${YTB_MUSIC_TV_UID:-$(id -u)}"
export YTB_MUSIC_TV_GID="${YTB_MUSIC_TV_GID:-$(id -g)}"

mkdir -p "$PROJECT_DIR/data"
cd "$PROJECT_DIR"
exec docker compose "$@"
