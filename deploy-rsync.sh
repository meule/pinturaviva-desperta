#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"

: "${DEPLOY_HOST:?Set DEPLOY_HOST}"
: "${DEPLOY_USER:?Set DEPLOY_USER}"
: "${DEPLOY_PATH:?Set DEPLOY_PATH}"

DEPLOY_PORT="${DEPLOY_PORT:-22}"

"$ROOT_DIR/build-dist.sh"

rsync -avz --delete \
  -e "ssh -p $DEPLOY_PORT" \
  "$DIST_DIR"/ \
  "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/"

echo "Deployed $DIST_DIR to $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH"
