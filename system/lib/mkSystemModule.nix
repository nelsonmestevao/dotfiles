{ lib }:
name: body:
{
  config,
  lib,
  pkgs,
  ...
}@args:
{
  options.dotfiles.modules.${name}.enable = lib.mkEnableOption "Enable ${name} system configuration.";

  config = lib.mkIf config.dotfiles.modules.${name}.enable (body args);
}
