{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.unstable.opencode
    pkgs.unstable.opencode-claude-auth
  ];
}
