{ ... }:

{
  # pkgs.grayjay's src (fetchFromGitLab -> fetchgit, fetchLFS + fetchSubmodules
  # both true, to pull in JustCef's vendored prebuilt CEF binaries) has a long
  # silent stall after its initial fast git clone. Root cause, confirmed by
  # live reproduction with `ss -tnpi`: nixpkgs' nix-prefetch-git only runs
  # `git lfs install` (registers the smudge filter) - it never calls `git lfs
  # pull` or `git lfs fetch`. LFS content download then happens purely as a
  # side effect of `git checkout` / `git submodule update --checkout`
  # invoking the smudge filter per-blob, SERIALLY, one file at a time over a
  # single connection - confirmed via `ss -tnpi` showing exactly one TCP
  # socket to the LFS server for the whole multi-hundred-MB download. That's
  # much slower than `git lfs pull`, which uses LFS's batch API to enumerate
  # every needed object upfront and downloads them with real concurrency
  # (default 8 parallel transfers, `lfs.concurrenttransfers`). With no TTY in
  # the build sandbox, git-lfs's progress bar is also suppressed entirely, so
  # this reads as "fast clone, then total silence" rather than a visibly slow
  # download.
  #
  # nix-prefetch-git-parallel-lfs (this directory) is nixpkgs'
  # pkgs/build-support/fetchgit/nix-prefetch-git with a minimal fix: install
  # the LFS filter with --skip-smudge (so checkout writes pointer files
  # instead of smudge-downloading one at a time), then explicitly run `git
  # lfs pull` (and, per submodule, `git submodule foreach --recursive 'git
  # lfs pull'`) right after checkout, before `.git` removal - letting LFS's
  # batch/concurrent path do the real downloading. upstream-nixpkgs-reference
  # .patch in this directory is the same change as a diff against nixpkgs'
  # file, kept for an eventual upstream submission (not submitted from here).
  #
  # Verified byte-for-byte identical output against the unpatched fetcher
  # across three local LFS test repos (plain LFS repo,
  # LFS repo + LFS-using submodule, and LFS repo + one LFS submodule + one
  # plain submodule) before staging this. Not verified against the real
  # gitlab.futo.org fetch end-to-end (that's the whole multi-hundred-MB, slow
  # -network fetch this is meant to speed up - didn't want to burn that time
  # *and* compete with a live rebuild to prove it locally); the underlying
  # mechanism (skip-smudge + explicit batched pull) is standard,
  # well-documented git-lfs practice, not something novel to this fetch.
  #
  # TODO: Upstream to nixpkgs - this is a real fetchgit bug affecting every
  # fetchLFS = true caller, not just grayjay. upstream-nixpkgs-reference.patch
  # in this directory is the same fix as a diff against nixpkgs' actual file,
  # ready to submit; hasn't been proposed there yet.
  #
  # This overrides only pkgs.grayjay's own fetch (via `fetcher`, which
  # fetchgit's derivation exposes as a plain, overridable attribute) rather
  # than pkgs.fetchgit itself - fetchgit is a function that hardcodes
  # `fetcher = ./nix-prefetch-git` at eval time (not a parameter), so there's
  # no clean way to override every fetchLFS caller in nixpkgs at once from
  # here without reimplementing fetchgit's ~250 lines of derivation-
  # construction logic. Scoping it to grayjay is more conservative anyway.
  # No new content hash needed: this is a fixed-output derivation, and the
  # verification above confirms the output tree this produces is identical
  # to the original fetcher's - only *how* it's fetched changes.
  nixpkgs.overlays = [
    (_: prev: {
      grayjay = prev.grayjay.overrideAttrs (old: {
        src = old.src.overrideAttrs (_: {
          fetcher = ./nix-prefetch-git-parallel-lfs;
        });
      });
    })
  ];
}
