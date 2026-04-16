{ pkgs, ... }:
let
  # I want v59 at least to be able to use CLI tools
  ext = pkgs.unstable.gnomeExtensions.caffeine;
in
{
  home.packages = [ ext ];
  dotfiles.programs.gnome.enabledExtensions = [ ext.extensionUuid ];
  dotfiles.programs.gnome.extensionSchemaDirs = [
    "${ext}/share/gnome-shell/extensions/${ext.extensionUuid}/schemas"
  ];
}
