{ pkgs, ... }:
let
  ext = pkgs.unstable.gnomeExtensions.smart-home;
in
{
  home.packages = [ ext ];
  dotfiles.programs.gnome.enabledExtensions = [ ext.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${ext}/share/gnome-shell/extensions/${ext.extensionUuid}/schemas"
  ];
}
