{
  pkgs,
  ...
}:
{
  platforms = [ "linux" ];

  home.packages = with pkgs; [
    tableplus
  ];
}
