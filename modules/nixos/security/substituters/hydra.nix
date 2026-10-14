{
  nix = {
    settings = {
      trusted-substituters = [
        "https://hydra.nixos.org/"
      ];
      trusted-public-keys = [
        "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
      ];
    };
  };
}
