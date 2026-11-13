{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    shotcut
  ];
}
