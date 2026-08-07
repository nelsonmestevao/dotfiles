# ── Users (home-manager) ───────────────────────────────────────────────────
{
  nixpkgs-unstable,
  claude-code,
  codex-cli-nix,
  herdr,
  zen-browser,
  zed,
}:
{
  "nelson.estevao" = {
    name = "Nelson Estevão";
    extraGroups = [
      "docker"
    ];
    overlays = [
      claude-code.overlays.default
      codex-cli-nix.overlays.default
      herdr.overlays.default
      (final: prev: { zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default; })
      (final: prev: {
        unstable = import nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      })
    ];
    extraSpecialArgs = { };
  };
  nelson = {
    name = "Nelson Estevão";
    extraGroups = [
      "docker"
      "libvirtd"
      "lpadmin"
      "networkmanager"
      "wheel"
    ];
    overlays = [
      claude-code.overlays.default
      codex-cli-nix.overlays.default
      herdr.overlays.default
      (final: prev: { zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default; })
      # TODO: Remove this once GNOME 50 is released
      # GNOME 50 patch while waiting for PR #506387 to be merged
      # https://github.com/NixOS/nixpkgs/pull/506387
      (final: prev: {
        gnomeExtensions = prev.gnomeExtensions // {
          pop-shell = prev.gnomeExtensions.pop-shell.overrideAttrs (_: {
            version = "1.2.0-unstable-2026-03-31";

            src = prev.fetchFromGitHub {
              owner = "pop-os";
              repo = "shell";
              rev = "7898b65c20735057faf0797f8ed056704ca55f0d";
              hash = "sha256-MmHoOxymo0QSRbRcSbFiv82+QWAwIwXwg/wyGQGVYiI=";
            };
          });

          # GNOME 49/50 support while waiting for upstream PR #33 to be merged
          # https://github.com/mechtifs/wiggle/pull/33
          wiggle = prev.gnomeExtensions.wiggle.overrideAttrs (_: {
            version = "5-unstable-2026-05-05";

            src = prev.fetchFromGitHub {
              owner = "nicolas-farrie";
              repo = "wiggle";
              rev = "894f1f7b99b53937e41b292ac6cc2dc1c56657e9";
              hash = "sha256-AjXqZg4plvSKjJ4yPgIVUGfPL08vih9teHO/nB9bayY=";
            };
          });
        };
      })
      (final: prev: { zed-editor = zed.packages.${prev.stdenv.hostPlatform.system}.default; })
      (final: prev: {
        unstable = import nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      })
    ];
    extraSpecialArgs = { };
  };
}
