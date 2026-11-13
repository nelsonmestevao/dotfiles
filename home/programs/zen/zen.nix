{
  pkgs,
  ...
}:
{
  # Window buttons can be hidden in about:config with
  # zen.view.experimental-no-window-controls.
  home.packages = with pkgs; [
    # about:config zen.view.experimental-no-window-controls
    # zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    zen-browser
  ];
}
