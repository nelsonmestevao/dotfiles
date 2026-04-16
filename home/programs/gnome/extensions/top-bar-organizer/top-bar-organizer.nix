{
  config,
  lib,
  pkgs,
  ...
}:
let
  top-bar-organizer = pkgs.gnomeExtensions.top-bar-organizer;
in
{
  home.packages = [ top-bar-organizer ];

  dotfiles.programs.gnome.enabledExtensions = [ top-bar-organizer.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${top-bar-organizer}/share/gnome-shell/extensions/${top-bar-organizer.extensionUuid}/schemas"
  ];

  dconf.settings."org/gnome/shell/extensions/top-bar-organizer" = {
    left-box-order = [
      "activities"
      "Space Bar"
    ];
    center-box-order = [ "dateMenu" ];
    right-box-order = [
      "freonMenu"
      "screenSharing"
      "system-monitor@gnome-shell-extensions.gcampax.github.com"
      "dwellClick"
      "vitalsMenu"
      "a11y"
      "color-picker@tuberry"
      "screenRecording"
      "wol@mnorlin.se"
      "keyboard"
      "pop-shell"
      "quickSettings"
    ];
  };
}
