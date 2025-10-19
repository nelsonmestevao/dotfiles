{ lib }:
name: body:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dotfiles.programs.${name}.enable = lib.mkEnableOption "Enable ${name} configuration.";

  config = lib.mkIf config.dotfiles.programs.${name}.enable (body {
    inherit config lib pkgs;
  });
}
