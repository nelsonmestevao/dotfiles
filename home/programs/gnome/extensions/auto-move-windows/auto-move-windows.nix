{ pkgs, ... }:
let
  ext = pkgs.gnomeExtensions.auto-move-windows;
in
{
  home.packages = [ ext ];
  dotfiles.programs.gnome.enabledExtensions = [ ext.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${ext}/share/gnome-shell/extensions/${ext.extensionUuid}/schemas"
  ];
}
