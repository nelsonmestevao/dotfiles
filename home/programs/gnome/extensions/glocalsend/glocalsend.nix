{ pkgs, ... }:
{
  # ── Package Override ─────────────────────────────────────────────────
  package = pkgs.callPackage ./package.nix { };

  # ── dconf Settings ───────────────────────────────────────────────────
  dconf.settings."org/gnome/shell/extensions/glocalsend" = {
    auto-disable-enabled = false;
    download-folder = "/home/nelson/Downloads/#LocalSend";
    port = 53317;
  };
}
