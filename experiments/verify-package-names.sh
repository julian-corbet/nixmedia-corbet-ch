#!/usr/bin/env bash
# Reproduces the verification every (arch, nixpkgs) pair in lib/media.nix was checked against
# before being committed: `pacman -Si` (and, for the one AUR-only name, the AUR RPC) for the Arch
# side; a force-evaluating `nix eval` for the nixpkgs side. This is the manual, human-readable
# half — experiments/validate-nixpkgs-names.nix is the machine-checkable half for the nixpkgs
# side alone (wire it into CI; this script is for re-running the FULL verification by hand after
# touching lib/media.nix, the way it was actually done to build this catalogue in the first
# place, 2026-08-03, against a live CachyOS host's pacman and a pinned nixpkgs rev).
#
# Usage: ./experiments/verify-package-names.sh [nixpkgs-rev]
#   Defaults to the rev infra's own flake.lock had pinned when this catalogue was built.
set -euo pipefail
rev="${1:-1d4e0f865d68258aada31e68e6d79c8c463f3b34}"
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Every arch name in lib/media.nix that is NOT marked aur = true.
official_names=(vlc gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav gst-plugin-pipewire vlc-plugins-all libdvdcss handbrake intel-media-driver)
# Every arch name that IS marked aur = true — pacman -Si cannot see these at all; they are
# checked against the AUR's own RPC instead. Empty today — vlc is an official-repo package on
# both platforms — but the loop below stays in place for whatever graphical entry arrives next
# (an image viewer, a comics reader) that turns out not to be.
aur_names=()

echo "== Arch official repos (pacman -Si) =="
official_status=0
for pkg in "${official_names[@]}"; do
  if pacman -Si "$pkg" >/dev/null 2>&1; then
    echo "OK   $pkg"
  else
    echo "MISS $pkg -- not in an official repo on this host; check whether lib/media.nix still marks it aur = false"
    official_status=1
  fi
done

echo
echo "== AUR-only names (aur.archlinux.org RPC v5 -- pacman -Si never sees these) =="
aur_status=0
for pkg in "${aur_names[@]}"; do
  if curl -sf "https://aur.archlinux.org/rpc/v5/info?arg[]=$pkg" | grep -q '"resultcount":1'; then
    echo "OK   $pkg (AUR)"
  else
    echo "MISS $pkg -- not found in the AUR either; lib/media.nix's arch name is wrong"
    aur_status=1
  fi
done

echo
echo "== nixpkgs, force-evaluated against rev $rev (delegates to validate-nixpkgs-names.nix) =="
result="$(nix-instantiate --eval --strict \
  --arg nixpkgs "(fetchTarball \"https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz\")" \
  experiments/validate-nixpkgs-names.nix)"
echo "$result"
nixpkgs_status=0
if [[ "$result" != *"missing = [ ]"* ]]; then
  nixpkgs_status=1
fi

echo
if [[ $official_status -eq 0 && $aur_status -eq 0 && $nixpkgs_status -eq 0 ]]; then
  echo "All names verified against real repositories."
else
  echo "One or more names failed verification -- see MISS/missing lines above." >&2
  exit 1
fi
