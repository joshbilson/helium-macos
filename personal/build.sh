#!/usr/bin/env bash
# Build an unsigned Helium .dmg into build/. First run takes several hours.
# Usage: personal/build.sh [--clean|--resume] [arm64|x86_64]
#   --clean   remove build/src first (needed after a failed source prep, per docs/building.md)
#   --resume  skip source prep and continue from configure + compile (after a failure past patching)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "$root/.venv/bin/python3" ] || { echo "run personal/bootstrap.sh first" >&2; exit 1; }

mode=full
case "${1:-}" in
  --clean) rm -rf "$root/build/src"; shift ;;
  --resume) mode=resume; shift ;;
esac
arch="${1:-$(uname -m)}"

export PATH="$root/.venv/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export _root_dir="$root"
unset MACOS_CERTIFICATE_NAME # unsigned local build

# Domain substitution rewrites googleapis.com in depot_tools/gsutil.py to a dead domain, and
# install_cipd_deps.py (libclang) runs gsutil after that, so gsutil can't download itself.
# Pre-install gsutil from the real URL and point depot_tools at it. Build tooling only:
# nothing here ends up in the browser.
gsutil_version=5.35
export DEPOT_TOOLS_GSUTIL_BIN_DIR="$root/build/gsutil-cache"
gsutil_dir="$DEPOT_TOOLS_GSUTIL_BIN_DIR/gsutil_$gsutil_version"
if [ ! -f "$gsutil_dir/gsutil/install.flag" ]; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/gsutil.zip" "https://storage.googleapis.com/pub/gsutil_$gsutil_version.zip"
  mkdir -p "$gsutil_dir"
  unzip -q "$tmp/gsutil.zip" -d "$gsutil_dir"
  echo "Dropped by personal/build.sh" > "$gsutil_dir/gsutil/install.flag"
  rm -rf "$tmp"
fi

# TypeScript resolves types by walking up for node_modules, so a stray one above the checkout
# (e.g. ~/node_modules) leaks into Chromium's ts_library steps and fails them.
dir="$(dirname "$root")"
while [ "$dir" != / ]; do
  if [ -d "$dir/node_modules" ]; then
    echo "error: $dir/node_modules breaks Chromium's TypeScript steps; move it aside for the build" >&2
    exit 1
  fi
  dir="$(dirname "$dir")"
done

mkdir -p "$root/build"
log="$root/build/build-$(date +%Y%m%d-%H%M%S).log"
echo "building $arch ($mode), log: $log"

cd "$root"
if [ "$mode" = resume ]; then
  # Same steps build.sh runs after prepare_sources.
  cmd=(bash -c 'set -euo pipefail; source devutils/shared.sh; configure_build "$1" false true; helium_build chrome/installer/mac; "$0"/sign_and_package_app.sh' "$root" "$arch")
else
  cmd=(./build.sh "$arch")
fi

# caffeinate keeps the Mac awake for the whole build.
caffeinate -dims "${cmd[@]}" 2>&1 | tee "$log"

echo
ls -lh "$root"/build/*.dmg
