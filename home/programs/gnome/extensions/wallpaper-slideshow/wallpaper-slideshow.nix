{
  config,
  lib,
  pkgs,
  ...
}:
let
  wallpapers = "${config.home.homeDirectory}/Pictures/Bing";

  bingToJxl = pkgs.writeShellApplication {
    name = "bing-to-jxl";
    runtimeInputs = with pkgs; [
      coreutils
      libjxl
    ];
    text = builtins.readFile ./bing-to-jxl.sh;
  };
in
{
  # ── Package Override ─────────────────────────────────────────────────
  package = pkgs.callPackage ./package.nix { };

  # ── dconf Settings ───────────────────────────────────────────────────
  dconf.settings."org/gnome/shell/extensions/azwallpaper" = {
    slideshow-directory = wallpapers;
    slideshow-pause-notifications = false;
    slideshow-show-quick-settings-entry = true;
    # The slideshow dates a picture by when its file was made, and converting
    # it to JPEG XL makes a new file. "Newest" would follow the order the
    # pictures were converted in, not the order Bing showed them.
    slideshow-queue-sort-type = "Random";
    bing-download-directory = wallpapers;
    bing-wallpaper-download = true;
    # How many past days to fetch, 1 to 8. 1 fetches only today's picture.
    # 0 is out of range, and GSettings would use the default, 8. Only
    # bing-wallpaper-download = false stops the downloads.
    bing-wallpaper-download-count = 1;
    bing-wallpaper-notify-on-error = false;
    bing-wallpaper-resolution = "UHD";
  };

  # ── Services ─────────────────────────────────────────────────────────
  # Bing sends JPGs. Each one becomes a JPEG XL as soon as it lands, which
  # takes less space and gives back the same JPG with djxl.
  systemd.user.services.bing-to-jxl = {
    Unit.Description = "Convert new Bing wallpapers to JPEG XL";
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe bingToJxl} ${lib.escapeShellArg wallpapers}";
    };
    # Also run at login, for any JPG left over: from before this service, or
    # from a run that failed.
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.paths.bing-to-jxl = {
    Unit.Description = "Watch the Bing wallpaper folder for new JPGs";
    Path.PathChanged = wallpapers;
    Install.WantedBy = [ "default.target" ];
  };
}
