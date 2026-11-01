{
  enableFor,
  disableFor,
  enableForRoles,
  ...
}:
{
  # Desktop Environment
  dotfiles.programs.gnome.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.gnome.extensions = {
    accent-directories.enable = true;
    auto-move-windows.enable = true;
    blur-my-shell.enable = true;
    caffeine.enable = true;
    color-picker.enable = true;
    draw-on-gnome.enable = true;
    glocalsend.enable = enableForRoles [ "desktop" ];
    pop-shell.enable = true;
    rudra.enable = false;
    smart-home.enable = true;
    space-bar.enable = true;
    top-bar-organizer.enable = true;
    vitals.enable = true;
    wake-on-lan.enable = true;
    wallpaper-slideshow.enable = enableForRoles [ "desktop" ];
    wiggle.enable = true;
  };

  dotfiles.programs.hyprland.enable = false;

  # Shells
  dotfiles.programs.zsh.enable = true;

  # Desktop Launchers & App Switchers
  dotfiles.programs.vicinae.enable = enableForRoles [ "desktop" ];

  # Terminals
  dotfiles.programs.ghostty.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.fonts.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.jetbrains.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.tableplus.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.vscode.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.zed.enable = enableForRoles [ "desktop" ];

  # Programming Languages
  dotfiles.programs.elixir.enable = true;
  dotfiles.programs.erlang.enable = true;
  dotfiles.programs.flutter.enable = true;
  dotfiles.programs.golang.enable = true;
  dotfiles.programs.haskell.enable = true;
  dotfiles.programs.nodejs.enable = true;
  dotfiles.programs.python.enable = true;
  dotfiles.programs.ruby.enable = true;
  dotfiles.programs.rust.enable = true;

  # Dev Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.bruno.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.btop.enable = true;
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.codex.enable = true;
  dotfiles.programs.colima.enable = enableFor [ "Remote-Nelson-Estevao" ];
  dotfiles.programs.copilot.enable = true;
  dotfiles.programs.cpufetch.enable = true;
  dotfiles.programs.ctop.enable = true;
  dotfiles.programs.curl.enable = true;
  dotfiles.programs.cursor.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.devcontainer.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.docker.enable = true;
  dotfiles.programs.exiftool.enable = true;
  dotfiles.programs.eza.enable = true;
  dotfiles.programs.fastfetch.enable = true;
  dotfiles.programs.fd.enable = true;
  dotfiles.programs.ffmpeg.enable = true;
  dotfiles.programs.figlet.enable = true;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.glab.enable = true;
  dotfiles.programs.glow.enable = true;
  dotfiles.programs.herdr-app.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.herdr-core.enable = enableForRoles [ "desktop" "server" ];
  dotfiles.programs.httpie.enable = true;
  dotfiles.programs.hyperfine.enable = true;
  dotfiles.programs.imagemagick.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.kamal.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.mysql.enable = false;
  dotfiles.programs.ngrok.enable = true;
  dotfiles.programs.onefetch.enable = true;
  dotfiles.programs.opencode.enable = true;
  dotfiles.programs.orca.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.pandoc.enable = true;
  dotfiles.programs.podman.enable = false;
  dotfiles.programs.projectionist.enable = true;
  dotfiles.programs.rclone.enable = true;
  dotfiles.programs.restic.enable = true;
  dotfiles.programs.ripgrep.enable = true;
  dotfiles.programs.shellcheck.enable = true;
  dotfiles.programs.shfmt.enable = true;
  dotfiles.programs.speedtest.enable = true;
  dotfiles.programs.sqlite.enable = true;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.terraform.enable = enableFor [ "framework" ];
  dotfiles.programs.unoconv.enable = true;
  dotfiles.programs.unzip.enable = true;
  dotfiles.programs.watchman.enable = true;
  dotfiles.programs.wget.enable = true;
  dotfiles.programs.yq.enable = true;
  dotfiles.programs.zellij.enable = true;
  dotfiles.programs.zoxide.enable = true;

  # Typesetting
  dotfiles.programs.latex.enable = enableFor [ "framework" ];
  dotfiles.programs.typst.enable = true;

  # Desktop Applications
  dotfiles.programs.beeper.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.bitwarden.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.calibre.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.chrome.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.digikam.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.espanso.enable = false;
  dotfiles.programs.gimp.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.inkscape.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.libreoffice.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.localsend.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.obsidian.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.pdfmixtool.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.pinta.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.thunderbird.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.typora.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.vivaldi.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.wine.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.zeal.enable = enableForRoles [ "desktop" ];
  dotfiles.programs.zen.enable = enableForRoles [ "desktop" ];

  dotfiles.packages.enable = true;
}
