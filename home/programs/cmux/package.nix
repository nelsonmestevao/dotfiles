# cmux 0.65, while nixpkgs-unstable still ships 0.64. 0.65 adds syntax
# highlighting to the file editor.
{ pkgs }:
let
  cmux = pkgs.unstable.cmux.overrideAttrs (
    finalAttrs: _: {
      version = "0.65.2.2";
      src = pkgs.fetchurl {
        url = "https://github.com/manaflow-ai/cmux/releases/download/v${finalAttrs.version}/cmux-macos.dmg";
        hash = "sha256-GOiEjhnU4I/wrvsw8YD9s+r7PzLws2E5Q1GljlBdOX8=";
      };
    }
  );
in
pkgs.expiry.untilUpstreamHas cmux.version pkgs.unstable.cmux
  "Delete home/programs/cmux/package.nix and install pkgs.unstable.cmux in cmux.nix."
  cmux
