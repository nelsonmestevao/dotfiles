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
      # Leave alone what this file doesn't list. With "uninstall", every switch
      # tried to remove all the formulae installed outside this repo (awscli,
      # colima, docker and many more) and failed, because git-kasa needs some
      # of them. The cost: an app taken out of the lists below stays installed
      # until you `brew uninstall` it.
      cleanup = "none";
    };

    taps = [ "remoteoss/kasa" ];

    # CLI formulae. Prefer nixpkgs via home.packages; list here only what nix
    # lacks or what must come from Homebrew.
    brews = [
      "git-kasa"
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
