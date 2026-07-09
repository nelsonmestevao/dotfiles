{
  config,
  lib,
  pkgs,
  ...
}:
{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024;
      priority = 10;
    }
  ];

  boot.kernel.sysctl."vm.swappiness" = 150;
}
