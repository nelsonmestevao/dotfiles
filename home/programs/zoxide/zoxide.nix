{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    zoxide
  ];

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    alias j=z
    alias ji=zi
  '';
}
