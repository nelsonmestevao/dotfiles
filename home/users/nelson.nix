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
  # Desktop Environment
  dotfiles.programs.gnome.enable = enableFor [ "framework" ];
  dotfiles.programs.gnome.extensions = {
    accent-directories.enable = true;
    auto-move-windows.enable = true;
    blur-my-shell.enable = true;
    caffeine.enable = true;
    color-picker.enable = true;
    draw-on-gnome.enable = true;
    glocalsend.enable = enableFor [ "framework" ];
    pop-shell.enable = true;
    rudra.enable = false;
    smart-home.enable = true;
    space-bar.enable = true;
    top-bar-organizer.enable = true;
    user-themes-x.enable = true;
    vitals.enable = true;
    wake-on-lan.enable = true;
    wallpaper-slideshow.enable = enableFor [ "framework" ];
    wiggle.enable = false;
  };

  dotfiles.programs.hyprland.enable = false;

  # Shells
  dotfiles.programs.zsh.enable = true;

  # Desktop Launchers & App Switchers
  dotfiles.programs.vicinae.enable = true;

  # Terminals
  dotfiles.programs.ghostty.enable = enableFor [ "framework" ];
  dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.fonts.enable = enableFor [ "framework" ];
  dotfiles.programs.jetbrains.enable = enableFor [ "framework" ];
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.vscode.enable = enableFor [ "framework" ];
  dotfiles.programs.zed.enable = enableFor [ "framework" ];

  # Programming Languages
  dotfiles.programs.elixir.enable = true;
  dotfiles.programs.erlang.enable = true;
  dotfiles.programs.flutter.enable = true;
  dotfiles.programs.golang.enable = true;
  dotfiles.programs.haskell.enable = true;
  dotfiles.programs.nodejs.enable = true;
  dotfiles.programs.python.enable = true;
  dotfiles.programs.ruby.enable = true;

  # Dev Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.bruno.enable = enableFor [ "framework" ];
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.codex.enable = true;
  dotfiles.programs.copilot.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.exiftool.enable = true;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.glow.enable = true;
  dotfiles.programs.httpie.enable = true;
  dotfiles.programs.hyperfine.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.mysql.enable = false;
  dotfiles.programs.ngrok.enable = true;
  dotfiles.programs.opencode.enable = true;
  dotfiles.programs.pandoc.enable = true;
  dotfiles.programs.podman.enable = disableFor [ "thinkpad" ];
  dotfiles.programs.rclone.enable = true;
  dotfiles.programs.restic.enable = false;
  dotfiles.programs.sqlite.enable = true;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.terraform.enable = enableFor [ "framework" ];
  dotfiles.programs.unoconv.enable = true;
  dotfiles.programs.watchman.enable = true;
  dotfiles.programs.zoxide.enable = true;

  # Typesetting
  dotfiles.programs.latex.enable = enableFor [ "framework" ];
  dotfiles.programs.typst.enable = true;

  # Desktop Applications
  dotfiles.programs.beeper.enable = enableFor [ "framework" ];
  dotfiles.programs.bitwarden.enable = enableFor [ "framework" ];
  dotfiles.programs.calibre.enable = enableFor [ "framework" ];
  dotfiles.programs.chrome.enable = enableFor [ "framework" ];
  dotfiles.programs.digikam.enable = enableFor [ "framework" ];
  dotfiles.programs.espanso.enable = false;
  dotfiles.programs.gimp.enable = enableFor [ "framework" ];
  dotfiles.programs.inkscape.enable = enableFor [ "framework" ];
  dotfiles.programs.libreoffice.enable = enableFor [ "framework" ];
  dotfiles.programs.localsend.enable = enableFor [ "framework" ];
  dotfiles.programs.obsidian.enable = enableFor [ "framework" ];
  dotfiles.programs.pinta.enable = enableFor [ "framework" ];
  dotfiles.programs.typora.enable = enableFor [ "framework" ];
  dotfiles.programs.vivaldi.enable = enableFor [ "framework" ];
  dotfiles.programs.wine.enable = enableFor [ "framework" ];
  dotfiles.programs.zeal.enable = enableFor [ "framework" ];
  dotfiles.programs.zen.enable = enableFor [ "framework" ];

  dotfiles.packages.enable = true;
}
