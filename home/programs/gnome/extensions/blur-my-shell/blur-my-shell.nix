{
  config,
  lib,
  pkgs,
  ...
}:
let
  blur-my-shell = pkgs.gnomeExtensions.blur-my-shell;
in
{
  home.packages = [ blur-my-shell ];

  dotfiles.programs.gnome.enabledExtensions = [ blur-my-shell.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${blur-my-shell}/share/gnome-shell/extensions/${blur-my-shell.extensionUuid}/schemas"
  ];

  dconf.settings = {
    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = true;
      sigma = 20;
      whitelist = [ "com.mitchellh.ghostty" ];
    };
  };
}
