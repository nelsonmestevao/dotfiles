{
  lib,
  ...
}:
{
  # NOTE: nix-darwin does NOT install Homebrew itself — it only drives
  # `brew bundle` to reconcile the declarations below with what's installed.
  # Install Homebrew first (once, manually):
  #   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # (or add the `nix-homebrew` flake to also manage the brew installation.)
  homebrew = {
    enable = true;

    # Homebrew's post-install step, which nix-darwin otherwise skips: emit
    # `eval "$(<prefix>/bin/brew shellenv zsh)"` into /etc/zshrc so `brew` and
    # its installed binaries land on the interactive shell's PATH (also sets
    # HOMEBREW_*, MANPATH, and completions).
    enableZshIntegration = true;

    # This Mac is managed by Workbrew, which sends every `brew` call through
    # its own /opt/workbrew/bin/brew. Point nix-darwin there so it uses that
    # one. `brew bundle` runs through it under sudo during a switch, and that
    # works.
    prefix = "/opt/workbrew";

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    taps = [
      "nikitabobko/tap"
      "remoteoss/kasa"
    ];

    # Every Homebrew formula installed on this Mac. With `cleanup = "uninstall"`,
    # a switch removes any formula that isn't listed here, so the list has to
    # be complete, even where Nix installs the same tool. New CLI tools belong
    # in home.packages; add one here only when it has to come from Homebrew.
    # `brew bundle dump --file=-` prints what is installed, to compare.
    brews = [
      # Tools
      "awscli"
      "colima"
      "coreutils"
      "curl"
      "docker"
      "docker-compose"
      "ffmpeg"
      "gdal"
      "ghostscript"
      "git-kasa"
      "git-lfs"
      "gum"
      "pdftk-java"
      "pgformatter"
      "weasyprint"
      "yq"

      # What git-kasa needs. During a switch Homebrew can't see git-kasa's
      # needs (it comes from another tap), so without these lines it tries to
      # remove them and then refuses, because git-kasa needs them.
      "gettext"
      "git"
      "json-c"
      "libunistring"
      "pcre2"

      # Libraries that were installed on purpose. Other formulae above need
      # most of them; listing them keeps a switch from depending on Homebrew
      # to get that right.
      "libpq"
      "lz4"
      "openssl@3"
      "ossp-uuid"
      "pkgconf"
      "poppler"
      "readline"
      "zlib"
    ];

    # GUI apps / casks.
    casks = [
      "1password-cli"
      "ghostty"
      "nikitabobko/tap/aerospace"
      "openlogi"
      "raycast"
    ];

    # Mac App Store apps (requires the `mas` CLI). Format: "App Name" = <id>;
    masApps = { };
  };

  # `brew shellenv` above adds Workbrew's /opt/homebrew/share/zsh folders to
  # the places zsh looks for completions. zsh's completion setup (compinit)
  # only trusts folders that root or you own and that nobody else can write
  # to. Workbrew's are group-writable, so oh-my-zsh warns about "insecure
  # completion-dependent directories" on every shell start. This takes those
  # folders out again; everything else `brew shellenv` sets (PATH, HOMEBREW_*)
  # stays. It is still needed with Home Manager's compinit off: oh-my-zsh's
  # own run is the one that warns.
  programs.zsh.interactiveShellInit = lib.mkAfter ''
    fpath=(''${fpath:#/opt/homebrew/share/zsh*})
  '';
}
