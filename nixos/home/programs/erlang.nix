{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    # erlang_27
  ];

  xdg.configFile."rebar/rebar.config" = mkSymlink "rebar.config";
}
