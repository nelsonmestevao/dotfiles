{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.mise ];

  home.shellAliases.mr = "mise run";
}
