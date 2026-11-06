{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    eza
  ];
}
