{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    exiftool
  ];
}
