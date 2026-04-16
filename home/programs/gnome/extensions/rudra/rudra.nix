{
  config,
  lib,
  pkgs,
  ...
}:
let
  rudra = pkgs.callPackage ./package.nix { };
in
{
  home.packages = [ rudra ];

  dotfiles.programs.gnome.enabledExtensions = [ rudra.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${rudra}/share/gnome-shell/extensions/${rudra.extensionUuid}/schemas"
  ];

  dconf.settings."org/gnome/shell/extensions/rudra" = {
    toggle-launcher = [ "<Alt>space" ];
  };
}
