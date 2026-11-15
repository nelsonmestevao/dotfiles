# Programs that are only a package. Each name here is a program like one in
# its own folder: it gets dotfiles.programs.<name>.enable, and a user file
# turns it on. Give a program its own folder once it needs more than its
# package, like a config file or a setting.
#
# There's no `platforms` here: nixpkgs itself refuses to evaluate a package
# that doesn't build for the host's OS.
pkgs:
with pkgs;
{
  inherit
    # core utils
    dig
    dust
    fop
    gnupg
    gping
    grex
    gvfs
    libsecret
    lftp
    mpv
    nushell
    ouch
    poppler-utils # pdftotext, pdftohtml, etc
    tldr
    yazi

    # build tools
    autoconf
    automake
    gcc
    gnumake
    pkg-config

    # development tools
    bc
    eva
    k6
    silicon
    stripe-cli

    # containers & cloud
    cloudflared

    # ISO tools
    impression

    # performance & benchmarking
    scc
    tokei

    # TUIs
    lazysql

    # misc
    nix-search-tv
    dconf2nix
    cached-nix-shell
    fuse
    appimage-run
    terminaltexteffects
    ;

  inherit (llvmPackages_20) clang-tools;
}
// import ../scripts.nix { inherit pkgs; }
