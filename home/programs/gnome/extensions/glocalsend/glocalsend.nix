{
  config,
  lib,
  pkgs,
  ...
}:
let
  glocalsend = pkgs.callPackage ./package.nix { };
in
{
  home.packages = [ glocalsend ];

  dotfiles.programs.gnome.enabledExtensions = [ glocalsend.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${glocalsend}/share/gnome-shell/extensions/${glocalsend.extensionUuid}/schemas"
  ];
}
