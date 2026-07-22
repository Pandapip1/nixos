# Pandapip1's NixOS Configuration Repository

Testing Codeberg sync

Manual update:

```
sudo nixos-rebuild switch --flake git+https://codeberg.org/Pandapip1/nixos.git?shallow=1
```

Build disk images

```
nix build .#nixosConfigurations.<whatever>.config.system.build.diskoImages --impure
```

impure needed for cross
