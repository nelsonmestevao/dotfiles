{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    mysql84
    libxml2
    libxml2.dev
    pkg-config
  ];

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    export PKG_CONFIG_PATH=${pkgs.libxml2.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
  '';
}
