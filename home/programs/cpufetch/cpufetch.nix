{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    cpufetch
  ];
}
