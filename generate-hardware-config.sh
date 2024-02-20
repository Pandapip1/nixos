#!/usr/bin/env bash

mkdir -p $(git rev-parse --show-toplevel)/hardware
nixos-generate-config --show-hardware-config > $(git rev-parse --show-toplevel)/hosts/$(hostname)/hardware-configuration.nix
