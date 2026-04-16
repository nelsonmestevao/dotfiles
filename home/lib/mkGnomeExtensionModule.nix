{ lib }:
name: body:
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  mkSymlink =
    relativePath:
    config.lib.dotfiles.mkSymlinkFrom
      "${config.dotfiles.directory}/home/programs/gnome/extensions/${name}"
      relativePath;
in
{
  options.dotfiles.programs.gnome.extensions.${name}.enable =
    lib.mkEnableOption "Enable ${name} GNOME extension.";

  config = lib.mkIf (
    config.dotfiles.programs.gnome.enable
    && config.dotfiles.programs.gnome.extensions.${name}.enable
  ) (body (args // { inherit mkSymlink; }));
}
