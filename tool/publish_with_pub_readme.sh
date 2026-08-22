#!/usr/bin/env bash
# Publish wp_pivot_flutter with the package-facing README (.pub_readme.md)
# instead of the GitHub-facing README.md, without committing the swap.
#
# Usage:
#   ./tool/publish_with_pub_readme.sh          # dry-run by default
#   ./tool/publish_with_pub_readme.sh --publish  # actually publish
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .pub_readme.md ]]; then
  echo "error: .pub_readme.md not found" >&2
  exit 1
fi

restore() {
  if [[ -f .README.md.github_backup ]]; then
    mv .README.md.github_backup README.md
    echo "README.md restored."
  fi
}
trap restore EXIT

# Swap in the pub-facing readme (never committed: we restore on exit)
cp README.md .README.md.github_backup
cp .pub_readme.md README.md

if [[ "${1:-}" == "--publish" ]]; then
  flutter pub publish --force
else
  echo "--- DRY RUN (use --publish to publish) ---"
  flutter pub publish --dry-run
fi
