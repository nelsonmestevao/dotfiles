{
  config,
  lib,
  pkgs,
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

    # This Mac is managed by Workbrew, which forces every `brew` call through
    # its wrapper at /opt/workbrew/bin/brew (HOMEBREW_FORCE_BREW_WRAPPER).
    # Point nix-darwin at that prefix so it invokes the wrapper instead of the
    # raw /opt/homebrew/bin/brew. NOTE: Workbrew also rejects brew run via sudo,
    # and nix-darwin runs `brew bundle` inside the sudo activation — so this may
    # still fail with "invoked by /usr/bin/sudo". If it does, disable this
    # module and manage casks through a Workbrew Brewfile instead.
    prefix = "/opt/workbrew";

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    taps = [ ];

    # CLI formulae. Prefer nixpkgs via home.packages; list here only what nix
    # lacks or what must come from Homebrew.
    brews = [
    ];

    # GUI apps / casks.
    casks = [
      "1password-cli"
      "raycast"
      "ghostty"
    ];

    # Mac App Store apps (requires the `mas` CLI). Format: "App Name" = <id>;
    masApps = { };
  };
}
