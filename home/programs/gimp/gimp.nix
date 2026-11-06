{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    gimp
  ];
}
