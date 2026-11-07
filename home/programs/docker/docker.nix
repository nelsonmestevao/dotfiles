{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      cup-docker
      docker-buildx
      docker-compose
      dockerfmt
      lazydocker
    ]
    # On Linux the docker CLI comes from the system daemon package
    # (virtualisation.docker), so only ship the standalone client here on
    # Darwin, where colima provides just the daemon.
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      docker-client
    ];
}
