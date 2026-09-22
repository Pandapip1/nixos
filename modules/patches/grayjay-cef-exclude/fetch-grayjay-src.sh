#!/usr/bin/env bash
# Custom Grayjay.Desktop source fetcher. Excludes the CEF/prebuilt content
# this build doesn't need, instead of downloading it and discarding it.
#
# JustCef/DotCef.csproj (a pure C# project, no native build step in
# nixpkgs' grayjay derivation) only ever copies prebuilt/<RuntimeIdentifier>/**
# for the RID being published; native/third_party/cef/** (8 full per-platform
# CEF SDK archives, ~500MB-2GB+ each) is never referenced by that csproj at
# all - it's only used by JustCef's own native/CMakeLists.txt build, which
# this package never invokes. So: skip LFS smudge entirely on first checkout
# (writes tiny ~130-byte pointer files), then selectively `git lfs pull`
# only prebuilt/<platform>/** inside the JustCef submodule.
set -euo pipefail

out="$1"
platform="$2"  # "linux-arm64" or "linux-x64"

export HOME="$TMPDIR"
export GIT_CONFIG_NOSYSTEM=1
export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-bundle.crt}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dir="$work/src"
mkdir -p "$dir"
cd "$dir"

echo "=== Grayjay.Desktop @ tag 17 ===" >&2
git init -q --initial-branch=master
git remote add origin https://gitlab.futo.org/videostreaming/Grayjay.Desktop.git
git lfs install --local >/dev/null
git fetch --depth 1 origin refs/tags/17
git checkout -q FETCH_HEAD

echo "=== small submodules, fetched normally ===" >&2
git submodule init
for path in Grayjay.Engine FUTO.MDNS SyncServer; do
  git submodule update --init --checkout --depth 1 -- "$path"
done

echo "=== JustCef: skip LFS smudge, then pull only prebuilt/$platform/** ===" >&2
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
  git lfs install --local >/dev/null
  git lfs pull --include="prebuilt/$platform/**"
)

echo "=== stripping .git for determinism ===" >&2
find "$dir" -name .git -print0 | xargs -0 rm -rf

mkdir -p "$(dirname "$out")"
cp -a "$dir" "$out"
