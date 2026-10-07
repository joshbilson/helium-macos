#!/usr/bin/env bash
# Pull the latest Helium release (new Chromium + security fixes) into this fork, then rebuild.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

git remote get-url upstream >/dev/null 2>&1 ||
  git remote add upstream https://github.com/imputnet/helium-macos.git

before="$(cat helium-chromium/chromium_version.txt)"
git fetch upstream
git merge --no-edit upstream/main
git submodule update --init --recursive
after="$(cat helium-chromium/chromium_version.txt)"

echo "Chromium $before -> $after"
if [ "$before" != "$after" ]; then
  echo "New Chromium: rebuild with personal/build.sh --clean"
fi
