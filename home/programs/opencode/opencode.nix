{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    pkgs.unstable.opencode
    pkgs.unstable.opencode-claude-auth
  ];
}
