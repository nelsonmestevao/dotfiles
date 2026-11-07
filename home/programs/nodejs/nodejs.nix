{
  config,
  lib,
  mkSymlink,
  ...
}:
{
  # Node itself comes from mise; this is what mise installs next to it.
  home.file.".default-npm-packages" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-npm-packages"
  );
}
