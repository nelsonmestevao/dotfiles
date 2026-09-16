{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    bat
  ];

  xdg.configFile."bat/config" = mkSymlink "config";

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    alias cat='bat -p'
  '';
}
