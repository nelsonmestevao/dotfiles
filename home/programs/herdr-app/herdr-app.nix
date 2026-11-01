{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    herdr-app
  ];

  # Herdr writes through these links (settings, zoom, theme picks), but it
  # doesn't see edits made through them while running: restart the window
  # after changing them by hand. Herdr owns everything else in the folder.
  xdg.configFile = {
    "herdr-app/keys.json" = mkSymlink "keys.json";
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
