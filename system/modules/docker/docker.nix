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

  environment.systemPackages = with pkgs; [
    docker
    docker-buildx
    docker-compose
    cup-docker
  ];
}
