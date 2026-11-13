{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    github-copilot-cli
  ];
}
