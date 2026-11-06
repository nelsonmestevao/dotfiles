{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    inkscape
  ];
}
