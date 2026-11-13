{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    localsend
  ];
}
