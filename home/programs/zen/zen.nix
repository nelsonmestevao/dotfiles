{
  config,
  lib,
  pkgs,
  # zen-browser,
  ...
}:
{
  home.packages = with pkgs; [
    # about:config zen.view.experimental-no-window-controls
    # zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    zen-browser
  ];
}
