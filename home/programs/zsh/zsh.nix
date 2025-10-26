{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    zsh
  ];

  home.sessionVariables = {
    SHELL = "${pkgs.zsh}/bin/zsh";
  };

  programs.zsh.enable = true;

  home.file.".zshrc" = mkSymlink "zshrc";
}
