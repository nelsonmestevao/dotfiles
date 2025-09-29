{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../lib
  ];

  home.packages = with pkgs; [
    direnv
  ];

  xdg.configFile."direnv/direnvrc" = config.lib.dotfiles.mkSymlink "nixos/home/programs/direnv/direnvrc";
}
