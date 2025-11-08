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
    config.lib.dotfiles.mkSymlinkFrom "${config.home.homeDirectory}/.dotfiles/home/programs/${name}" relativePath;
in
{
  options.dotfiles.programs.${name}.enable = lib.mkEnableOption "Enable ${name} configuration.";

  config = lib.mkIf config.dotfiles.programs.${name}.enable (body
  (args // { inherit mkSymlink; })
  );
}
