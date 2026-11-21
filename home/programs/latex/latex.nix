{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    texliveFull
    zathura
  ];

  home.file.".latexmkrc" = mkSymlink ./latexmkrc;
}
