{
  config,
  lib,
  pkgs,
  ...
}:
{
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
  dotfiles.programs.mysql.enable = false;
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.rclone.enable = true;
  dotfiles.programs.restic.enable = false;
  dotfiles.programs.sqlite.enable = true;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.vscode.enable = true;
  dotfiles.programs.wezterm.enable = true;
  dotfiles.programs.wine.enable = true;
  dotfiles.programs.zed.enable = true;
  dotfiles.programs.zen.enable = true;
  dotfiles.programs.zoxide.enable = true;

  dotfiles.packages.enable = true;
}
