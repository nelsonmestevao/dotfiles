# Programs that are only a package. Each name here is a program like one in
# its own folder: it gets dotfiles.programs.<name>.enable, and a user file
# turns it on. Give a program its own folder once it needs more than its
# package, like a config file or a setting.
#
# There's no `platforms` here. nixpkgs refuses most packages that don't build
# for the host's OS, but not all: gvfs and fuse evaluate on a Mac. Run
# `bin/build home` there before you turn on a Linux tool.
pkgs:
with pkgs;
{
  inherit
    appimage-run
    autoconf
    automake
    bc
    btop
    cached-nix-shell
    calibre
    cloudflared
    codex
    colima
    cpufetch
    crit
    ctop
    curl
    dconf2nix
    devcontainer
    dig
    digikam
    discord
    dust
    eva
    exiftool
    fastfetch
    fd
    figlet
    flutter
    fop
    fuse
    gcc
    gimp
    glab
    glow
    gnupg
    gping
    grex
    gvfs
    httpie
    hyperfine
    imagemagick
    impression
    inkscape
    jq
    k6
    kamal
    lazysql
    lftp
    libjxl
    libreoffice
    libsecret
    localsend
    mpv
    ngrok
    nushell
    obsidian
    onefetch
    ouch
    pandoc
    pdfmixtool
    pinta
    pkg-config
    poppler-utils # pdftotext, pdftohtml, etc
    rclone
    ripgrep
    scc
    shellcheck
    shfmt
    shotcut
    silicon
    slack
    spotify
    stripe-cli
    terminaltexteffects
    terraform
    thunderbird
    tldr
    tokei
    typora
    typst
    unzip
    vivaldi
    vlc
    watchman
    wget
    yq
    zeal
    ;

  inherit (kdePackages) kdenlive;
  inherit (llvmPackages_20) clang-tools;
  inherit (unstable) beeper;

  # Named after the program, not the package.
  chrome = google-chrome;
  copilot = github-copilot-cli;
  ffmpeg = ffmpeg-full;
  mysql = mysql84;
  rust = rustup;
  speedtest = speedtest-cli;
  zen = zen-browser; # about:config zen.view.experimental-no-window-controls
}
// import ./scripts.nix { inherit pkgs; }
