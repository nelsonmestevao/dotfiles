{
  lib,
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

  # NixOS deletes old generations once a month (system/nixos.nix), the users'
  # homes too. A home on another Linux has nothing doing that, so it cleans
  # its own profile, by the same rule (config/cleanup.nix).
  programs.nh.clean = {
    enable = pkgs.stdenv.hostPlatform.isLinux && host.platform == null;
    dates = "monthly";
    extraArgs = toString (import ../config/cleanup.nix);
  };

  # No `man home-configuration.nix`. Building it made every evaluation print a
  # warning about a derivation named options.json, once for each home. The
  # options are on the web.
  manual.manpages.enable = false;

  # The nix-index-database module turns nix-index on in every home that
  # imports it, and every home does. This puts it back to off, so a user file
  # turns it on like any program: dotfiles.programs.nix-index.
  programs.nix-index.enable = lib.mkOverride 900 false;

  # The release this home was first set up with; see config/hosts.nix.
  home.stateVersion = host.stateVersion;
}
