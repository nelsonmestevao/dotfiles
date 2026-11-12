{
  enableFor,
  valueFor,
  ...
}:
{
  # Desktop Environment
  dotfiles.programs.gnome.enable = enableFor [ "desktop" ];
  dotfiles.programs.gnome.extensions = {
    accent-directories.enable = true;
    auto-move-windows.enable = true;
    blur-my-shell.enable = true;
    caffeine.enable = true;
    color-picker.enable = true;
    draw-on-gnome.enable = true;
    glocalsend.enable = true;
    pop-shell.enable = true;
    rudra.enable = false;
    smart-home.enable = true;
    space-bar.enable = true;
    top-bar-organizer.enable = true;
    vitals.enable = true;
    wake-on-lan.enable = true;
    wallpaper-slideshow.enable = true;
    wiggle.enable = true;
  };

  dotfiles.programs.hyprland.enable = false;

  # Shells
  dotfiles.programs.zsh.enable = true;
  dotfiles.programs.zsh.showHost = enableFor [ "server" ];

  # Desktop Launchers & App Switchers
  dotfiles.programs.vicinae.enable = enableFor [ "desktop" ];

  # Terminals
  dotfiles.programs.ghostty.enable = enableFor [ "desktop" ];
  dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.fonts.enable = enableFor [ "desktop" ];
  dotfiles.programs.jetbrains.enable = enableFor [ "desktop" ];
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.tableplus.enable = enableFor [ "desktop" ];
  dotfiles.programs.vscode.enable = enableFor [ "desktop" ];
  dotfiles.programs.zed.enable = enableFor [ "desktop" ];

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
  dotfiles.programs.bruno.enable = enableFor [ "desktop" ];
  dotfiles.programs.btop.enable = true;
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.claude.skills = true;
  dotfiles.programs.codex.enable = true;
  dotfiles.programs.colima.enable = enableFor [ "darwin" ];
  dotfiles.programs.copilot.enable = true;
  dotfiles.programs.cpufetch.enable = true;
  dotfiles.programs.ctop.enable = true;
  dotfiles.programs.curl.enable = true;
  dotfiles.programs.cursor.enable = false;
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
  # The key that signs commits. A host that isn't named here signs nothing.
  dotfiles.programs.git.signingKey = valueFor {
    framework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINt6s4KNjVHcH0qA0CPKWYPyCTPXkbwXFlfljrToN8b6";
    thinkpad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINt6s4KNjVHcH0qA0CPKWYPyCTPXkbwXFlfljrToN8b6";
    temis = "~/.ssh/id_ed25519.pub";
  };
  dotfiles.programs.git-sim.enable = enableFor [ "framework" ];
  dotfiles.programs.glab.enable = true;
  dotfiles.programs.glow.enable = true;
  dotfiles.programs.herdr-app.enable = enableFor [ "desktop" ];
  dotfiles.programs.herdr-core.enable = enableFor [
    "desktop"
    "server"
  ];
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
  dotfiles.programs.opencode.enable = false;
  dotfiles.programs.orca.enable = enableFor [ "desktop" ];
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
  dotfiles.programs.zellij.enable = false;
  dotfiles.programs.zoxide.enable = true;

  # Typesetting
  dotfiles.programs.latex.enable = enableFor [ "framework" ];
  dotfiles.programs.typst.enable = true;

  # Desktop Applications
  dotfiles.programs.beeper.enable = enableFor [ "desktop" ];
  dotfiles.programs.bitwarden.enable = enableFor [ "desktop" ];
  dotfiles.programs.calibre.enable = enableFor [ "desktop" ];
  dotfiles.programs.chrome.enable = enableFor [ "desktop" ];
  dotfiles.programs.digikam.enable = false;
  dotfiles.programs.discord.enable = enableFor [ "framework" ];
  dotfiles.programs.espanso.enable = false;
  dotfiles.programs.gimp.enable = enableFor [ "desktop" ];
  dotfiles.programs.inkscape.enable = enableFor [ "desktop" ];
  dotfiles.programs.kdenlive.enable = enableFor [ "framework" ];
  dotfiles.programs.libreoffice.enable = enableFor [ "desktop" ];
  dotfiles.programs.localsend.enable = enableFor [ "desktop" ];
  dotfiles.programs.obs.enable = enableFor [ "framework" ];
  dotfiles.programs.obsidian.enable = enableFor [ "desktop" ];
  dotfiles.programs.pdfmixtool.enable = enableFor [ "desktop" ];
  dotfiles.programs.pinta.enable = false;
  dotfiles.programs.shotcut.enable = false;
  dotfiles.programs.slack.enable = enableFor [ "desktop" ];
  dotfiles.programs.spotify.enable = enableFor [ "desktop" ];
  dotfiles.programs.thunderbird.enable = enableFor [ "desktop" ];
  dotfiles.programs.typora.enable = enableFor [ "desktop" ];
  dotfiles.programs.vivaldi.enable = enableFor [ "desktop" ];
  dotfiles.programs.vlc.enable = false;
  dotfiles.programs.wine.enable = false;
  dotfiles.programs.zeal.enable = false;
  dotfiles.programs.zen.enable = enableFor [ "desktop" ];

  dotfiles.packages.enable = true;
}
