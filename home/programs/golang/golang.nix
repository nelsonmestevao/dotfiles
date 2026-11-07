{
  config,
  lib,
  mkSymlink,
  ...
}:
{
  # Go itself comes from mise; this is what mise installs next to it.
  home.file.".default-golang-pkgs" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-golang-pkgs"
  );
}
