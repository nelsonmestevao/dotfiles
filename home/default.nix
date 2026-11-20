{
  username,
  pkgs,
  host,
  ...
}:
{
  imports = [
    ./users/${username}.nix
  ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";

  # Where tools install commands for the user: stack and cabal, Herdr.app on a
  # Mac (herdr-core and hc), pipx. Every home needs it, not just one program.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # On another distro (a Linux host with no `platform`), help its desktop find
  # what Nix installs: apps and icons in the menu, cursors, terminfo and the
  # graphics drivers. The first switch says how to set up the drivers.
  targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux && host.platform == null;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.nh.enable = true;

  # The release this home was first set up with; see config/hosts.nix.
  home.stateVersion = host.stateVersion;
}
