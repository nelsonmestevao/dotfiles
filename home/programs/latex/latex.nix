{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    texliveFull
    # latexmkrc previews with it (latexmk -pv).
    zathura
  ];

  home.file.".latexmkrc" = mkSymlink ./latexmkrc;
}
