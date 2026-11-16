# xtool, from the fork with macOS app support, asset catalogs (CarKit) and
# Icon Composer icons: the asset-catalogs branch of
# https://github.com/Pandapip1/xtool, which is based on macos-app-target.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-12";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "xtool";
    rev = "7d44346878ca033ed79ad2312c5b8ed3a16bf503";
    hash = "sha256-rxR7SrnPhfXk1iGFAI7wzI5efbmt585rJzHl+iX2dp4=";
  };
}
