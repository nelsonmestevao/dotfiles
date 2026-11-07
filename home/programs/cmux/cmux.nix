{
  pkgs,
  mkSymlink,
  ...
}:
{
  platforms = [ "darwin" ];

  # nixpkgs still ships 0.64; 0.65 adds syntax highlighting to the file editor.
  home.packages = [
    (pkgs.unstable.cmux.overrideAttrs (
      finalAttrs: _: {
        version = "0.65.2.2";
        src = pkgs.fetchurl {
          url = "https://github.com/manaflow-ai/cmux/releases/download/v${finalAttrs.version}/cmux-macos.dmg";
          hash = "sha256-GOiEjhnU4I/wrvsw8YD9s+r7PzLws2E5Q1GljlBdOX8=";
        };
      }
    ))
  ];

  # Terminal settings come from ghostty's config; cmux.json holds cmux-owned
  # settings such as keyboard shortcuts.
  xdg.configFile."cmux/cmux.json" = mkSymlink "cmux.json";
}
