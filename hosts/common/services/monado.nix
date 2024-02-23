{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    python39
    vulkan-loader
    vulkan-headers
    # libeigen3-dev but it's not in nixpkgs
    glslang
    libusb1
    libudev-zero
    libv4l
    xorg.libxcb
    xorg.xrandr
    openhmd
    doxygen
    wayland-protocols
    hidapi
    opencv
    libuvc
    libjpeg
    SDL2
    monado
  ];
}
