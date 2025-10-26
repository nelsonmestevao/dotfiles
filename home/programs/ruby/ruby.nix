{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    ruby_3_4
  ];

  home.file.".irbrc" = mkSymlink "irbrc";
  home.file.".default-gems" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-gems"
  );
}
