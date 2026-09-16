{ ... }:

let
  # The tip of all-fixes-3.0 on the fork. The series used to be exported as a
  # flat patch directory and applied to nixpkgs' 3.0.23 tarball, but the two
  # are not the same source: the fork's base is 3.0.23-2-1253-g1da0650bc4,
  # 1253 commits further along v30x, so every patch was being applied to a
  # tree it was not generated against. `patch` absorbed the drift as line
  # offsets until the ogg rework, whose context had moved too far and which
  # failed outright. Building the branch directly removes the question: what
  # is built here is exactly what was measured there.
  rev = "47a2d532cecc842f9006fbf7168d2f738c7a12b7";
  hash = "sha256-Em6xMKSCCIV+S3czUDqo8zT5l/Z9CxY192xCqCcHbLw=";
in
{
  nixpkgs.overlays = [
    (_: prev: {
      # Gapless and seamless playback work, in eight groups: the audio core's
      # drift correction and its bound; repeating an item in place rather than
      # rebuilding the input; the timestamps a demuxer reports across a seek,
      # for some twenty containers; the packetizers' handling of a break; the
      # pulse output's device latency and startup; the upstream fixes
      # backported alongside them; the dummy output's device simulation; and
      # the tests that hold the lot in place. Each commit on the branch says
      # what it changed and what was measured.
      vlc = prev.vlc.overrideAttrs (prevAttrs: {
        version = "3.0.23-unstable-2026-09-16";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "vlc";
          inherit rev hash;
        };

        # nixpkgs' own patches stay; ours are in the source now.
        patches = prevAttrs.patches or [ ];
      });
    })
  ];
}
