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
    # Herdr rings the tab's focused pane even while a side panel mod (notes,
    # files, graph) or a dialog has the keyboard. The patch drops the ring then.
    herdr-app = prev.herdr-app.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../home/programs/herdr-app/focus-ring-follows-keyboard.patch ];
    });
  })
  (final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  (final: prev: {
    gnomeExtensions = prev.gnomeExtensions // {
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
  (final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
]
