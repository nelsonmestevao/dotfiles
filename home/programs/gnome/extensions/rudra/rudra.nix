{ pkgs, ... }:
{
  package = pkgs.callPackage ./package.nix { };

  dconf.settings."org/gnome/shell/extensions/rudra" = {
    toggle-launcher = [ "<Alt>space" ];
  };
}
