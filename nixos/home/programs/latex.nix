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
    texliveFull
  ];

  home.file.".latexmkrc" = config.lib.dotfiles.mkSymlink "nixos/home/programs/latex/latexmkrc";
}

