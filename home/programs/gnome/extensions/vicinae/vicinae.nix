{
  pkgs,
  lib,
  mkSymlink,
  ...
}:
{
  # ── dconf Settings ───────────────────────────────────────────────────
  dconf.settings."org/gnome/shell/extensions/vicinae" = {
    show-status-indicator = false;
  };
}
