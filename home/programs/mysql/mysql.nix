{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    mysql84
  ];
}
