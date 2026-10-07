#!/usr/bin/env bash
# Build an unsigned Helium .dmg into build/. First run takes several hours.
# Usage: personal/build.sh [--clean] [arm64|x86_64]
#   --clean  remove build/src first (needed after a failed build, per docs/building.md)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "$root/.venv/bin/python3" ] || { echo "run personal/bootstrap.sh first" >&2; exit 1; }

if [ "${1:-}" = --clean ]; then
  rm -rf "$root/build/src"
  shift
fi
arch="${1:-$(uname -m)}"

export PATH="$root/.venv/bin:$PATH"
unset MACOS_CERTIFICATE_NAME # unsigned local build

mkdir -p "$root/build"
log="$root/build/build-$(date +%Y%m%d-%H%M%S).log"
echo "building $arch, log: $log"

# caffeinate keeps the Mac awake for the whole build.
cd "$root"
caffeinate -dims ./build.sh "$arch" 2>&1 | tee "$log"

echo
ls -lh "$root"/build/*.dmg
