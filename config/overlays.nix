# ── Overlays ───────────────────────────────────────────────────────────────
#
# Shared by every NixOS, nix-darwin and home-manager configuration, so a
# package fixed here is the same package everywhere. Takes all the flake
# inputs, so using a new flake only needs it in flake.nix `inputs` and its
# overlay here.
inputs: [
  inputs.claude-code.overlays.default
  inputs.codex-cli-nix.overlays.default
  inputs.herdr-app-nix.overlays.default
  # The orca flake's overlay names its app `orca`, which would replace GNOME's
  # screen reader of the same name (NixOS installs it with GNOME). Take the
  # app from that overlay but expose it as `orca-app` instead.
  (final: prev: { orca-app = (inputs.orca.overlays.default final prev).orca; })
  (_final: prev: {
    # Herdr rings the tab's focused pane even while a side panel mod (notes,
    # files, graph) or a dialog has the keyboard. The patch drops the ring then.
    # Fixed upstream in 558cf56 (herdrdev/herdr-app#362), after 0.1.12: drop the
    # patch once herdr-app-nix ships a newer version, or it stops applying.
    herdr-app = prev.herdr-app.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../home/programs/herdr-app/focus-ring-follows-keyboard.patch ];
    });
  })
  (_final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  (_final: prev: {
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
  (_final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
]
