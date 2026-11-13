{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.zoxide ];

  home.shellAliases = {
    j = "z";
    ji = "zi";
  };
}
