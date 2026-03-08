#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/assets/images" "$DIST_DIR/assets/video"

cp "$ROOT_DIR/index.html" "$DIST_DIR/index.html"
cp "$ROOT_DIR/styles.css" "$DIST_DIR/styles.css"
cp "$ROOT_DIR/script.js" "$DIST_DIR/script.js"
cp "$ROOT_DIR/robots.txt" "$DIST_DIR/robots.txt"
cp "$ROOT_DIR/sitemap.xml" "$DIST_DIR/sitemap.xml"
cp "$ROOT_DIR/.htaccess" "$DIST_DIR/.htaccess"

cp "$ROOT_DIR/assets/images/process-desk.jpg" "$DIST_DIR/assets/images/process-desk.jpg"
cp "$ROOT_DIR/assets/images/process-painting.jpg" "$DIST_DIR/assets/images/process-painting.jpg"
cp "$ROOT_DIR/assets/images/cat-gallery.jpg" "$DIST_DIR/assets/images/cat-gallery.jpg"
cp "$ROOT_DIR/assets/images/desperta-box.jpg" "$DIST_DIR/assets/images/desperta-box.jpg"
cp "$ROOT_DIR/assets/images/desperta-box-crop.jpg" "$DIST_DIR/assets/images/desperta-box-crop.jpg"
cp "$ROOT_DIR/assets/images/og-desperta.jpg" "$DIST_DIR/assets/images/og-desperta.jpg"

cp "$ROOT_DIR/assets/video/pinturaviva-desperta-hero.mp4" "$DIST_DIR/assets/video/pinturaviva-desperta-hero.mp4"
cp "$ROOT_DIR/assets/video/pinturaviva-desperta-full.mp4" "$DIST_DIR/assets/video/pinturaviva-desperta-full.mp4"

echo "Built $DIST_DIR"
