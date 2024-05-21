{ ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../environments/gnome.nix
    # Services
    ../services/nebula.nix
    # Applications
    ../applications/chromium.nix
    ../applications/vector.nix
    ../applications/codium.nix
    ../applications/envision.nix
    ../applications/telescope.nix
    ../applications/localsend.nix
    # Users
    ../users/gavin.nix
  ];
}
