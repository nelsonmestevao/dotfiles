{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    obs-cli
    obs-cmd
    obs-studio
  ];
}
