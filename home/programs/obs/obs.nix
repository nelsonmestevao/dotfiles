{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    obs-cli
    obs-cmd
    obs-studio
  ];
}
