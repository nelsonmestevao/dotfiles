{
  config,
  ...
}:
let
  wallpapers = "${config.home.homeDirectory}/Pictures/Bing";
in
{
  # ── dconf Settings ───────────────────────────────────────────────────
  dconf.settings."org/gnome/shell/extensions/azwallpaper" = {
    slideshow-directory = wallpapers;
    slideshow-pause-notifications = false;
    slideshow-show-quick-settings-entry = true;
    bing-download-directory = wallpapers;
    bing-wallpaper-download = true;
    # How many past days to fetch, 1 to 8. 1 fetches only today's picture.
    # 0 is out of range, and GSettings would use the default, 8. Only
    # bing-wallpaper-download = false stops the downloads.
    bing-wallpaper-download-count = 1;
    bing-wallpaper-notify-on-error = false;
    bing-wallpaper-resolution = "UHD";
  };
}
