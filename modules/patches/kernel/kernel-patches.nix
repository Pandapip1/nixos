{
  boot.kernelPatches = [
    {
      name = "non-desktop-override";
      patch = ./0001-drm-add-debugfs-non_desktop_override-for-connectors.patch;
    }
  ];
}
