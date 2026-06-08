{
  pkgs,
  lib,
  mkSymlink,
  username,
  ...
}:
{
  # ── dconf Settings ───────────────────────────────────────────────────
  dconf.settings."org/gnome/shell/extensions/azwallpaper" = {
    slideshow-directory = "/home/${username}/Pictures/Bing Wallpapers";
    slideshow-pause-notifications = false;
    slideshow-show-quick-settings-entry = true;
    bing-download-directory = "/home/${username}/Pictures/Bing Wallpapers";
    bing-wallpaper-download = true;
    bing-wallpaper-download-count = 8;
    bing-wallpaper-notify-on-error = false;
    bing-wallpaper-resolution = "UHD";
  };
}
