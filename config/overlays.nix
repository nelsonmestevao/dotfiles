# ── Overlays ───────────────────────────────────────────────────────────────
#
# Shared by every NixOS, nix-darwin and home-manager configuration, so a
# package fixed here is the same package everywhere. Takes all the flake
# inputs, so using a new flake only needs it in flake.nix `inputs` and its
# overlay here.
#
# A package patched here is wrapped in `final.expiry.expiresWhen` (see
# lib/expiry.nix), so it warns once the fix is out and the patch can go. It is
# also listed in lib/packages.nix, so it can be built on its own.
inputs:
let
  # True once nixpkgs has a copy of a GNOME extension made for the GNOME
  # version it ships. `gnomeExtensions` also holds copies made for older GNOME
  # versions, so finding one there proves nothing.
  madeForThisGnome =
    prev: extension:
    (prev."gnome${prev.lib.versions.major prev.gnome-shell.version}Extensions" or { })
      ? ${extension.extensionUuid};
in
[
  # `pkgs.expiry`: the helpers that make an override say when it can go.
  (_final: prev: { expiry = import ../lib/expiry.nix prev.lib; })
  inputs.claude-code.overlays.default
  inputs.codex-cli-nix.overlays.default
  inputs.herdr-app-nix.overlays.default
  # The orca flake's overlay names its app `orca`, which would replace GNOME's
  # screen reader of the same name (NixOS installs it with GNOME). Take the
  # app from that overlay but expose it as `orca-app` instead.
  (final: prev: { orca-app = (inputs.orca.overlays.default final prev).orca; })
  (final: prev: {
    # Herdr rings the tab's focused pane even while a side panel mod (notes,
    # files, graph) or a dialog has the keyboard. The patch drops the ring then.
    # Fixed in herdr-app's commit 558cf56 (herdrdev/herdr-app#362), after
    # 0.1.12. A build between releases may already have it, so this warns on
    # any new version: that is when someone has to look.
    herdr-app =
      final.expiry.expiresWhen (prev.herdr-app.version != "0.1.11")
        "herdr-app is now ${prev.herdr-app.version}. If it has upstream commit 558cf56, drop its patch in config/overlays.nix."
        (
          prev.herdr-app.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ../home/programs/herdr-app/focus-ring-follows-keyboard.patch ];
          })
        );
  })
  (_final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  (final: prev: {
    # vicinae's own build of the release flake.nix pins. It comes from
    # vicinae's cache, which system/modules/nixos/vicinae adds, so nothing
    # compiles it. nixpkgs-unstable is behind it, and going back would also
    # lose GNOME clipboard fixes. Once nixpkgs-unstable catches up, this
    # warns, and its copy, built by NixOS, can take over. The home program
    # and the system wrapper both use `pkgs.vicinae`.
    vicinae =
      let
        release = inputs.vicinae.packages.${prev.stdenv.hostPlatform.system}.default;
      in
      final.expiry.untilUpstreamHas release.version final.unstable.vicinae
        "Set vicinae to final.unstable.vicinae in config/overlays.nix. Then drop the vicinae input from flake.nix, and vicinae's cache from system/modules/nixos/vicinae and the build job in .github/workflows/ci.yml."
        release;
  })
  (final: prev: {
    gnomeExtensions = prev.gnomeExtensions // {
      # GNOME 49/50 support while waiting for upstream PR #33 to be merged
      # https://github.com/mechtifs/wiggle/pull/33
      wiggle =
        final.expiry.expiresWhen (madeForThisGnome prev prev.gnomeExtensions.wiggle)
          "nixpkgs has a wiggle made for this GNOME Shell now. Drop the wiggle override in config/overlays.nix."
          (
            prev.gnomeExtensions.wiggle.overrideAttrs (_: {
              version = "5-unstable-2026-05-05";

              src = prev.fetchFromGitHub {
                owner = "nicolas-farrie";
                repo = "wiggle";
                rev = "894f1f7b99b53937e41b292ac6cc2dc1c56657e9";
                hash = "sha256-AjXqZg4plvSKjJ4yPgIVUGfPL08vih9teHO/nB9bayY=";
              };
            })
          );
    };
  })
  (_final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
]
