{ lib, mkSymlink, ... }:
with lib.hm.gvariant;
{
  xdg.configFile."pop-shell/config.json" = mkSymlink "config.json";

  dconf.settings."org/gnome/shell/extensions/pop-shell" = {
    activate-launcher = [ ];
    fullscreen-launcher = false;
    show-title = true;
    smart-gaps = false;
    snap-to-grid = false;
    stacking-with-mouse = false;

    gap-inner = mkUint32 3;
    gap-outer = mkUint32 3;

    tile-by-default = true;

    tile-enter = [ "<Super><Shift>Return" ];

    tile-move-left = [ ];
    tile-move-right = [ ];
    tile-move-up = [ ];
    tile-move-down = [ ];

    tile-move-left-global = [ "<Super><Shift>h" ];
    tile-move-right-global = [ "<Super><Shift>l" ];
    tile-move-up-global = [ "<Super><Shift>k" ];
    tile-move-down-global = [ "<Super><Shift>j" ];

    stack = [ ];
    toggle-floating = [ "<Meta><Shift>Space" ];
  };
}
