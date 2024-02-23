{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    eigen
    gcc
    python3
    vulkan-loader
    vulkan-headers
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
