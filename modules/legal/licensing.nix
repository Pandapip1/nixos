{
  lib,
  ...
}:

{
  nixpkgs.config = {
    allowlistedLicenses = (with lib.licenses; [
    ]);
    allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) [
      # TODO: It's unclear what license these are under
      "cups-idprt-tspl"
      "vscode-extension-ms-vscode-remote-remote-ssh"
      "vscode-extension-ms-vscode-remote-remote-ssh-edit"
      "vscode-extension-github-codespaces"
      # TODO: This should be moved to lib.licenses
      "open-webui"
      "nrfconnect"
      "nrf-udev"
      "segger-jlink"
    ];
    segger-jlink.acceptLicense = true;
  };

  # Would use even non redistributable firmware if it were compatible with allowUnfree = false
  # TODO: Open report
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
