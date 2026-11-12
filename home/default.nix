{
  username,
  pkgs,
  host,
  ...
}:
{
  imports = [
    ./packages.nix
    ./users/${username}.nix
  ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Where tools install commands for the user: stack and cabal, Herdr.app on a
  # Mac (herdr-core and hc), pipx. Every home needs it, not just one program.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.nh.enable = true;

  # The release this home was first set up with; see config/hosts.nix.
  home.stateVersion = host.stateVersion;
}
