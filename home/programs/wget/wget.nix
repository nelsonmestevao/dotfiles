{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    wget
  ];
}
