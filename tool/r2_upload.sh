#!/usr/bin/env bash
# Upload research assets (video, frames, CSVs) to Cloudflare R2.
# Bucket: wp-pivot-assets, public at https://assets.chinmaykabi.com/wp-pivot/...
#
# Usage:
#   ./tool/r2_upload.sh local/path.mp4 wp-pivot/session-001/full.mp4
set -euo pipefail
BUCKET="wp-pivot-assets"
PUBLIC="https://assets.chinmaykabi.com"

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <local-file> <remote-key>" >&2
  echo "example: $0 capture.mp4 wp-pivot/session-001/full.mp4" >&2
  exit 1
fi

npx wrangler r2 object put "$BUCKET/$2" --file "$1" --remote
echo "public URL: $PUBLIC/$2"
