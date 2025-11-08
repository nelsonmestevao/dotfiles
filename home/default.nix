{
  config,
  lib,
  pkgs,
  username,
  zen-browser,
  ...
}:
{
  imports = [
    ./packages.nix
    ./users/${username}.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.nh.enable = true;

  home.packages = [
    # about:config zen.view.experimental-no-window-controls
    zen-browser.packages.${pkgs.system}.default
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";
}
