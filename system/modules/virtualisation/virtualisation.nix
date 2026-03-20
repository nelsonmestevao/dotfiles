{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.libvirtd.enable = true;

  environment.systemPackages = with pkgs; [
    vagrant
    libvirt
  ];
}
