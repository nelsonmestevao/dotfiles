{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    typst
  ];
}
