{ config, pkgs, ... }:
{
  package = pkgs.callPackage ./package.nix { };

  dconf.settings."org/gnome/shell/extensions/glocalsend" = {
    auto-disable-enabled = false;
    download-folder = "${config.home.homeDirectory}/Downloads/#LocalSend";
    port = 53317;
  };
}
