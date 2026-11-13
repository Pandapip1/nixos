# xtool, from the fork with macOS app support, asset catalogs (CarKit) and
# Icon Composer icons: the asset-catalogs branch of
# https://github.com/Pandapip1/xtool, which is based on macos-app-target.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-12";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "xtool";
    rev = "0efc9161c178a108226710b505360364cfa3a702";
    hash = "sha256-7MF7kXV8Yp0Jjlc+McFF+JAaR6fVUoR25HEz8gjN838=";
  };
}
