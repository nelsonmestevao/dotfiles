{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    yazi
  ];

  home.shellAliases.r = "yazi";
}
