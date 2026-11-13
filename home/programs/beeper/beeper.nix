{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    pkgs.unstable.beeper
  ];
}
