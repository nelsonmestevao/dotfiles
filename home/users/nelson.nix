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
  # Shell
  dotfiles.programs.zsh.enable = true;

  # WM
  dotfiles.programs.hyprland.enable = false;

  # Desktop Environments
  dotfiles.programs.gnome.enable = enableFor [ "framework" ];

  # Programming Languages
  dotfiles.programs.elixir.enable = true;
  dotfiles.programs.erlang.enable = true;
  dotfiles.programs.flutter.enable = true;
  dotfiles.programs.golang.enable = true;
  dotfiles.programs.haskell.enable = true;
  dotfiles.programs.nodejs.enable = true;
  dotfiles.programs.python.enable = true;
  dotfiles.programs.ruby.enable = true;

  # Applications and Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.calibre.enable = enableFor [ "framework" ];
  dotfiles.programs.bitwarden.enable = true;
  dotfiles.programs.bruno.enable = true;
  dotfiles.programs.chrome.enable = true;
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.codex.enable = true;
  dotfiles.programs.digikam.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.espanso.enable = false;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.ghostty.enable = true;
  dotfiles.programs.gimp.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.httpie.enable = true;
  dotfiles.programs.hyperfine.enable = true;
  dotfiles.programs.inkscape.enable = true;
  dotfiles.programs.jetbrains.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.latex.enable = true;
  dotfiles.programs.libreoffice.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.mysql.enable = false;
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.obsidian.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.pinta.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.podman.enable = true;
  dotfiles.programs.rclone.enable = true;
  dotfiles.programs.restic.enable = false;
  dotfiles.programs.sqlite.enable = true;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.typst.enable = true;
  dotfiles.programs.vscode.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.watchman.enable = true;
  dotfiles.programs.wezterm.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.wine.enable = true;
  dotfiles.programs.zeal.enable = true;
  dotfiles.programs.zed.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.zen.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.zoxide.enable = true;

  dotfiles.packages.enable = true;
}
