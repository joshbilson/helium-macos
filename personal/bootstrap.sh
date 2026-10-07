#!/usr/bin/env bash
# One-time setup of a Mac to build this Helium fork. Safe to re-run.
# Follows docs/building.md, but keeps Python deps in .venv instead of the system Python.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
min_free_gb=120

die() { echo "error: $*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || die "run this on the Mac, not $(uname -s)"
echo "arch: $(uname -m), macOS $(sw_vers -productVersion)"

# Full Xcode (not just the Command Line Tools), version 26+.
xcode_dir="$(xcode-select -p 2>/dev/null || true)"
case "$xcode_dir" in
  *Xcode*.app/*) ;;
  *) die "full Xcode not selected (got '${xcode_dir:-none}'). Install Xcode 26 from the App Store, then: sudo xcode-select -s /Applications/Xcode.app" ;;
esac
xcode_major="$(xcodebuild -version | awk 'NR==1 {split($2, v, "."); print v[1]}')"
[ "$xcode_major" -ge 26 ] || die "Xcode $xcode_major found, Xcode 26+ required"
sudo xcodebuild -license accept 2>/dev/null || true

free_gb="$(df -g "$root" | awk 'NR==2 {print $4}')"
[ "$free_gb" -ge "$min_free_gb" ] || die "only ${free_gb}GB free, need about ${min_free_gb}GB for the Chromium source and build"

command -v brew >/dev/null || die "Homebrew missing: https://brew.sh"
# Only install what's missing: don't upgrade unrelated formulae (and fail on their warnings) as a side effect.
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
brew install python@3.13 wget coreutils readline quilt
brew unlink binutils 2>/dev/null || true

xcodebuild -downloadComponent MetalToolchain

"$(brew --prefix python@3.13)/bin/python3.13" -m venv "$root/.venv"
"$root/.venv/bin/pip" install --quiet httplib2==0.22.0 requests pillow

git -C "$root" submodule update --init --recursive
git -C "$root" remote get-url upstream >/dev/null 2>&1 ||
  git -C "$root" remote add upstream https://github.com/imputnet/helium-macos.git

echo
echo "Ready. Build with: personal/build.sh"
