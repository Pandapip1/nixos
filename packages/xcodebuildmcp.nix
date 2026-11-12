{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "xcodebuildmcp";
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "getsentry";
    repo = "XcodeBuildMCP";
    rev = "v${finalAttrs.version}";
    hash = "sha256-9Vi67nXlX7JbQSbSv+z+60pfAq1NpZy+/U4mkWaSIas=";
  };

  npmDepsHash = "sha256-PWvpblzfn0yM6hRmdJXzcqyegsytBRZGr0vJQYWdcuA=";

  # `build` goes through wireit; call the underlying step directly.
  # It regenerates src/version.ts (via tsx) and then runs tsup.
  npmBuildScript = "build:tsup";

  # Upstream's `bundle:axe` step downloads prebuilt AXe binaries, so it is
  # skipped here. The UI-automation tools find AXe through PATH or
  # XCODEBUILDMCP_AXE_PATH instead.

  meta = {
    description = "MCP server and CLI for building, running and testing Xcode projects";
    homepage = "https://github.com/getsentry/XcodeBuildMCP";
    license = lib.licenses.mit;
    mainProgram = "xcodebuildmcp";
    platforms = lib.platforms.darwin;
  };
})
