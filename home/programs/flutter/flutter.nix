{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    flutter
  ];
}
