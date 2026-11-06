{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bws
    bitwarden-cli
    # bitwarden-desktop
  ];
}
