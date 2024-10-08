{ ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../environments/gnome.nix
    # Services
    ../services/nebula.nix
    # Applications
    ../applications/chromium.nix
    ../applications/codium.nix
    # Users
    ../users/gavin.nix
  ];

  programs = {
    vector.enable = true;
    envision.enable = true;
  };
}
