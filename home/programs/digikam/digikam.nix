{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    digikam
  ];
}
