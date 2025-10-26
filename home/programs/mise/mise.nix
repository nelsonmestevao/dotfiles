{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    mise
  ];

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    alias mr='mise run'
  '';
}
