#!/usr/bin/env bash
# Custom Grayjay.Desktop source fetcher. Excludes the CEF/prebuilt content
# this build doesn't need, instead of downloading it and discarding it.
#
# Three paths are LFS-tracked across this repo + JustCef, all skipped:
# native/third_party/cef/** and prebuilt/<platform>/** (JustCef submodule -
# 8 full per-platform CEF SDK archives, ~4.5-5.5GB combined; CEF is built
# from JustCef's own native/CMakeLists.txt against pkgs.cef-binary by
# modules/patches/grayjay-cef-unvendor/ instead, which reproduces everything
# prebuilt/<platform>/ supplies), and Grayjay.ClientServer/deps/<platform>/**
# (top-level repo - ffmpeg, libcurl-impersonate, FUTO.Updater.Client,
# libcurlshim, ~350-400MB across 5 platforms). The last one is simpler than
# CEF: nixpkgs' grayjay package.nix's own postInstall ("Unvendor most
# stuff") already unconditionally rm -f's and symlinks over every file from
# deps/ to real nixpkgs packages before the build is done, so none of its
# actual bytes are ever used - confirmed directly in package.nix, not
# assumed. So: skip LFS smudge entirely on checkout (writes tiny ~130-byte
# pointer files for everything LFS-tracked, top-level repo included) and
# leave it at that - nothing needs a real download here anymore.
set -euo pipefail

out="$1"

export HOME="$TMPDIR"
export GIT_CONFIG_NOSYSTEM=1
export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-bundle.crt}"
export GIT_LFS_SKIP_SMUDGE=1

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dir="$work/src"
mkdir -p "$dir"
cd "$dir"

echo "=== Grayjay.Desktop @ tag 17: skip LFS smudge entirely ===" >&2
git init -q --initial-branch=master
git remote add origin https://gitlab.futo.org/videostreaming/Grayjay.Desktop.git
git fetch --depth 1 origin refs/tags/17
git checkout -q FETCH_HEAD

echo "=== small submodules (no LFS content - confirmed), fetched normally ===" >&2
git submodule init
for path in Grayjay.Engine FUTO.MDNS SyncServer; do
  git submodule update --init --checkout --depth 1 -- "$path"
done

echo "=== JustCef: skip LFS smudge entirely, no real download ===" >&2
git submodule init -- JustCef
justcef_sha=$(git ls-tree HEAD JustCef | awk '{print $3}')
rm -rf JustCef
mkdir -p JustCef
(
  cd JustCef
  git init -q --initial-branch=master
  git remote add origin "https://gitlab.futo.org/videostreaming/JustCef.git"
  export GIT_LFS_SKIP_SMUDGE=1
  git fetch --depth 1 origin "$justcef_sha"
  git checkout -q FETCH_HEAD
)

echo "=== stripping .git for determinism ===" >&2
find "$dir" -name .git -print0 | xargs -0 rm -rf

mkdir -p "$(dirname "$out")"
cp -a "$dir" "$out"
