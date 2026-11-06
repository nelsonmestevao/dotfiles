{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    kamal
  ];
}
