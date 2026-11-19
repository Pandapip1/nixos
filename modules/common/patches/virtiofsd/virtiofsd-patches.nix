{ ... }:

{
  nixpkgs.overlays = [
    (_: prev: {
      virtiofsd = prev.virtiofsd.overrideAttrs (prevAttrs: {
        # The legacy 32-bit mount ID name_to_handle_at()/statx() report is a
        # reused counter, and the kernel can legitimately hand back 0 for it
        # on mounts with no stable place in that legacy space (e.g. some
        # internal/anonymous mounts) - which MountFds::get() then treats as a
        # hard mismatch against the nonzero ID it cached earlier for the same
        # mount, failing disko's diskoImages VM builder with "Mount point's
        # (...) mount ID (0) does not match expected value (...)". This
        # switches both sides of that comparison to the unique, non-reused
        # 64-bit mount ID (STATX_MNT_ID_UNIQUE / AT_HANDLE_MNT_ID_UNIQUE,
        # Linux 6.8 / 6.12+) when the kernel supports it, falling back to the
        # legacy ID otherwise. This replaces the --inode-file-handles=never
        # wrapper nix-misc.nix used to carry as a workaround.
        patches = (prevAttrs.patches or [ ]) ++ [
          ./0001-prefer-unique-64-bit-mount-id.patch
        ];
      });
    })
  ];
}
