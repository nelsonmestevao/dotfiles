{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.docker.enable = true;

  virtualisation.docker.daemon.settings = {
    features = {
      buildkit = true;
    };
  };
}
