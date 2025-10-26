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
  # programs.zsh.initContent = builtins.readFile ./zshrc;

  home.file.".zshrc" = mkSymlink "zshrc";
}
