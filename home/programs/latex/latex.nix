{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.texliveFull ];

  home.file.".latexmkrc" = mkSymlink "latexmkrc";
}
