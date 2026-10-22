{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  # nixpkgs still ships 0.64; 0.65 adds syntax highlighting to the file editor.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
    with pkgs;
    [
      (unstable.cmux.overrideAttrs (
        finalAttrs: _: {
          version = "0.65.2";
          src = fetchurl {
            url = "https://github.com/manaflow-ai/cmux/releases/download/v${finalAttrs.version}/cmux-macos.dmg";
            hash = "sha256-L0vZjfdRQGdAjYk5j48ZBZAVo7uuYy0EdFFdS3bW7jY=";
          };
        }
      ))
    ]
  );

  # ── Symlinked Config Files ───────────────────────────────────────────
  # Terminal settings come from ghostty's config; cmux.json holds cmux-owned
  # settings such as keyboard shortcuts.
  xdg.configFile = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    "cmux/cmux.json" = mkSymlink "cmux.json";
  };
}
