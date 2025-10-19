{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.ghostty;
  ghosttyFilesPath = "nixos/home/programs/ghostty";
in
{
  options.dotfiles.programs.ghostty = {
    enable = lib.mkEnableOption "Enable Ghostty configuration.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      ghostty
    ];

    xdg.configFile."ghostty/config" = config.lib.dotfiles.mkSymlink "${ghosttyFilesPath}/config";
    xdg.configFile."ghostty/themes/Day" =
      config.lib.dotfiles.mkSymlink "${ghosttyFilesPath}/themes/Day";
    xdg.configFile."ghostty/themes/Night" =
      config.lib.dotfiles.mkSymlink "${ghosttyFilesPath}/themes/Night";
  };
}
