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

  # brew shellenv above prepends Workbrew-owned /opt/homebrew/share/zsh/
  # site-functions to fpath. compaudit only trusts dirs owned by root or the
  # current user, so a bare compinit after that prompts "insecure directories"
  # on each shell start. This strips those dirs right after shellenv; the rest
  # of shellenv (PATH, HOMEBREW_*) stays.
  #
  # Home Manager's bare compinit is now off (home/programs/zsh), but keep this:
  # oh-my-zsh's `compinit -i` skips these dirs and then prints an "insecure
  # completion-dependent directories" warning on every shell start.
  programs.zsh.interactiveShellInit = lib.mkAfter ''
    fpath=(''${fpath:#/opt/homebrew/share/zsh*})
  '';
}
