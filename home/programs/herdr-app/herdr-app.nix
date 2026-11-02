{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  home.packages = with pkgs; [
    herdr-app
  ];

  # Herdr writes through these links (settings, zoom, theme picks), but it
  # doesn't see edits made through them while running. After changing a file
  # by hand, `touch -h ~/.config/herdr-app/<file>` reloads it; for a mod,
  # restart the window. Herdr owns everything else in the folder.
  xdg.configFile = {
    "herdr-app/keys.json" = mkSymlink (if isDarwin then "keys/macos.json" else "keys/linux.json");
    "herdr-app/settings.json" = mkSymlink "settings.json";
    "herdr-app/layouts/main-mods.json" = mkSymlink "layouts/main-mods.json";
  }
  // lib.listToAttrs (
    map (m: lib.nameValuePair "herdr-app/mods/${m}" (mkSymlink "mods/${m}")) [
      "git-graph"
      "reviewer"
      "tab-notes"
      "tabs-mods"
    ]
  );
}
