{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    btop
  ];
}
