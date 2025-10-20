{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    texliveFull
  ];

  home.file.".latexmkrc" = mkSymlink "latexmkrc";
}
