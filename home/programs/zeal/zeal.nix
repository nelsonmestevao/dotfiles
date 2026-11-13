{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    zeal
  ];
}
