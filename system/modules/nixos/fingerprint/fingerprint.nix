{
  pkgs,
  ...
}:
{
  services.fprintd.enable = true;

  environment.systemPackages = [
    pkgs.fprintd
  ];
}
