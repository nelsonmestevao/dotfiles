{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # chromedriver
    google-chrome
  ];
}
