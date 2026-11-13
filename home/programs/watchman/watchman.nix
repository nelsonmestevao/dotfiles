{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    watchman
  ];
}
