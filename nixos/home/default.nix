{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./packages.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  dotfiles.programs.elixir.enable = true;
  dotfiles.programs.golang.enable = true;
  dotfiles.programs.haskell.enable = true;
  dotfiles.programs.nodejs.enable = true;
  dotfiles.programs.python.enable = true;
  dotfiles.programs.ruby.enable = true;

  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.ghostty.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.gnome.enable = true;
  dotfiles.programs.latex.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.sqlite.enable = true;

  dotfiles.packages.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.nh.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";
}
