{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.tmp.cleanOnBoot = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;
}
