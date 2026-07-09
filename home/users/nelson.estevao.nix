{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  enableFor = hosts: lib.elem hostname hosts;
  disableFor = hosts: !lib.elem hostname hosts;
in
{
  # Shells
  dotfiles.programs.zsh.enable = true;

  # Terminals
  dotfiles.programs.ghostty.enable = enableFor [ "framework" ];
  dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.nvim.enable = true;

  # Programming Languages
  #dotfiles.programs.elixir.enable = true;
  #dotfiles.programs.erlang.enable = true;

  # Dev Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.cursor.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.herdr.enable = true;
  dotfiles.programs.httpie.enable = true;
  dotfiles.programs.hyperfine.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.zoxide.enable = true;

  #dotfiles.packages.enable = true;
}
