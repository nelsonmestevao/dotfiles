{
  pkgs,
  ...
}:
{
  # Window buttons can be hidden in about:config with
  # zen.view.experimental-no-window-controls.
  home.packages = [ pkgs.zen-browser ];
}
