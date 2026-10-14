{ lib, ... }:

{
  nixpkgs.config = {
    allowlistedLicenses = with lib.licenses; [ sfl ];
    allowUnfreePredicate =
      pkg:
      lib.elem (lib.getName pkg) [
        # TODO: It is unclear what license these are under.
        "cups-idprt-tspl"
        "vscode-extension-ms-vscode-remote-remote-ssh"
        "vscode-extension-ms-vscode-remote-remote-ssh-edit"
        "vscode-extension-github-codespaces"
        # TODO: This should be moved to lib.licenses.
        "open-webui"
        "nrfconnect"
        "nrf-udev"
        "segger-jlink"
        "quartus-prime-lite"
        "quartus-prime-lite-unwrapped"
        "steam"
        "steam-unwrapped"
        "claude-code"
        # NVIDIA drivers.
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-kernel-modules"
      ];
    segger-jlink.acceptLicense = true;
  };
}
