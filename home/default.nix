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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.nh.enable = true;

  # Shell
  dotfiles.programs.zsh.enable = true;

  # WM
  dotfiles.programs.hyprland.enable = false;

  # Desktop Environments
  dotfiles.programs.gnome.enable = true;

  # Programming Languages
  dotfiles.programs.elixir.enable = true;
  dotfiles.programs.erlang.enable = true;
  dotfiles.programs.golang.enable = true;
  dotfiles.programs.haskell.enable = true;
  dotfiles.programs.nodejs.enable = true;
  dotfiles.programs.python.enable = true;
  dotfiles.programs.ruby.enable = true;

  # Programs and Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.espanso.enable = false;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.ghostty.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.jetbrains.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.latex.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.mysql.enable = true;
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.rclone.enable = true;
  dotfiles.programs.restic.enable = false;
  dotfiles.programs.sqlite.enable = true;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.vscode.enable = true;
  dotfiles.programs.wezterm.enable = true;
  dotfiles.programs.zed.enable = true;
  dotfiles.programs.zoxide.enable = true;

  dotfiles.packages.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";
}
