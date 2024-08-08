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
    ../applications/envision.nix
    # Users
    ../users/gavin.nix
  ];

  programs.vector.enable = true;
}
