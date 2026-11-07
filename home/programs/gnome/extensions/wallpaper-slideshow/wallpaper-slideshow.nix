{
  config,
  ...
}:
let
  wallpapers = "${config.home.homeDirectory}/Pictures/Bing Wallpapers";
in
{
  # ── dconf Settings ───────────────────────────────────────────────────
  dconf.settings."org/gnome/shell/extensions/azwallpaper" = {
    slideshow-directory = wallpapers;
    slideshow-pause-notifications = false;
    slideshow-show-quick-settings-entry = true;
    bing-download-directory = wallpapers;
    bing-wallpaper-download = true;
    bing-wallpaper-download-count = 8;
    bing-wallpaper-notify-on-error = false;
    bing-wallpaper-resolution = "UHD";
  };
}
