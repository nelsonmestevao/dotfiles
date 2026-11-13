{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    colima
  ];
}
