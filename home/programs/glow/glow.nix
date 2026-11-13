{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    glow
  ];
}
