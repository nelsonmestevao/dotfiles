{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    code-cursor
    cursor-cli
  ];
}
