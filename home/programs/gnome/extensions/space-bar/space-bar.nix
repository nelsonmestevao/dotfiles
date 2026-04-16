{
  config,
  lib,
  pkgs,
  ...
}:
let
  space-bar = pkgs.gnomeExtensions.space-bar;
in
{
  home.packages = [ space-bar ];

  dotfiles.programs.gnome.enabledExtensions = [ space-bar.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${space-bar}/share/gnome-shell/extensions/${space-bar.extensionUuid}/schemas"
  ];

  dconf.settings = {
    "org/gnome/shell/extensions/space-bar/behavior" = {
      always-show-numbers = false;
      position = "left";
      scroll-wheel = "workspaces-bar";
      show-empty-workspaces = true;
      toggle-overview = false;
    };

    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-activate-workspace-shortcuts = true;
      enable-move-to-workspace-shortcuts = true;
    };
  };
}
