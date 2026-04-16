_:
{
  dconf.settings = {
    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = true;
      sigma = 20;
      whitelist = [ "com.mitchellh.ghostty" ];
    };
  };
}
