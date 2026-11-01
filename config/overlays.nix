# ── Overlays (home-manager) ────────────────────────────────────────────────
#
# Shared by every user. Takes all the flake inputs, so using a new flake only
# needs it in flake.nix `inputs` and its overlay here.
inputs: [
  inputs.claude-code.overlays.default
  inputs.codex-cli-nix.overlays.default
  inputs.herdr-app-nix.overlays.default
  inputs.orca.overlays.default
  (final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
  })
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
  # Zed's own flake build on Linux only; macOS keeps the nixpkgs package.
  (
    final: prev:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
      zed-editor = inputs.zed.packages.${prev.stdenv.hostPlatform.system}.default;
    }
  )
  (final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
]
