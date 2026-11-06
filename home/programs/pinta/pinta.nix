{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    pinta
  ];
}
