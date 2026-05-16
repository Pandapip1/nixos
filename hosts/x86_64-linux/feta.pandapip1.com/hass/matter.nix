{
  services.home-assistant = {
    extraPackages = python3packages: with python3packages; [
      python-otbr-api
    ];
    extraComponents = [
      "matter"
    ];
  };
  services.openthread-border-router = {
    enable = true;
    backboneInterfaces = [ "enp1s0" ];
    rest.listenAddress = "[::]";
    web = {
      enable = true;
      listenAddress = "[::]";
    };
    radio = {
      device = "/dev/ttyACM0";
      baudRate = 115200;
    };
  };
  services.matter-server = {
    enable = true;
    openFirewall = true;
  };
}
