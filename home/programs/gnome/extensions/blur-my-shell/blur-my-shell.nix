_: {
  dconf.settings = {
    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = true;
      sigma = 20;
      whitelist = [ "com.mitchellh.ghostty" ];
    };

    # Static blur clones the wallpaper at the wrong size on mixed-resolution
    # multi-monitor setups, leaving part of the panel without a background.
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      static-blur = false;
    };
  };
}
