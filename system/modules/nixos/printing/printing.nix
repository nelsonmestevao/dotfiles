{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.brlaser
  ];
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  environment.systemPackages = [
    pkgs.cups-brother-hll3230cdw
  ];
}
