{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bruno
    bruno-cli
  ];
}
