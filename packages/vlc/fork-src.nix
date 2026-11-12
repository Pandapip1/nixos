# The tip of all-fixes-3.0 on the VLC fork, used by both the NixOS overlay
# (modules/nixos/patches/vlc/vlc-patches.nix) and the macOS build
# (packages/vlc/darwin.nix). See vlc-patches.nix for why the branch is built
# directly rather than applied as patches.
{ fetchFromGitHub }:

{
  version = "3.0.23-unstable-2026-09-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "vlc";
    rev = "bdd87c95b35570e36da8437a844d5c5020f55005";
    hash = "sha256-8cjtKYO/2SQlJh4BkFYYCpJILVS/BYNFgFfqjo0lnpw=";
  };
}
