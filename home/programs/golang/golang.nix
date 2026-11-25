{
  config,
  lib,
  mkSymlink,
  ...
}:
{
  # Go itself comes from mise; this is what mise installs next to it. mise
  # reads ~/.default-go-packages (asdf called it ~/.default-golang-pkgs).
  home.file.".default-go-packages" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink ./default-go-packages
  );
}
