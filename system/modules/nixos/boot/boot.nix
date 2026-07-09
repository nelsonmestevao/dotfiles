{
  config,
  lib,
  pkgs,
  onHost,
  ...
}:
lib.mkMerge [
  {
    boot.plymouth.enable = true;
  }
  (onHost "framework" {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;
  })
  (onHost "temis" {
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.configurationLimit = 10;
  })
]
