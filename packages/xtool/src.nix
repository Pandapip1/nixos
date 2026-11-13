# xtool, from the fork with macOS app support, asset catalogs (CarKit) and
# Icon Composer icons: the asset-catalogs branch of
# https://github.com/Pandapip1/xtool, which is based on macos-app-target.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-12";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "xtool";
    rev = "a6a961852775f70830814238c7e3570c4b8fde9e";
    hash = "sha256-bH9CW1lcozrrrKdWaH4z6TCj9ubdBSdWZxx1xxHLSDI=";
  };
}
