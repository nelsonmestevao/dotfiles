{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    pandoc
  ];
}
