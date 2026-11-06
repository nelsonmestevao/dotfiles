{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    ripgrep
  ];
}
