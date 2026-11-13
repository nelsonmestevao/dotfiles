{
  pkgs,
  ...
}:
{
  platforms = [ "linux" ];

  home.packages = [ pkgs.tableplus ];
}
