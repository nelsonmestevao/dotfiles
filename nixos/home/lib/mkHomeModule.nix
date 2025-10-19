{ lib }:
name: body:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.${name};
in
{
  options.dotfiles.programs.${name}.enable = lib.mkEnableOption "Enable ${name} configuration.";

  config = lib.mkIf cfg.enable (body {
    inherit config lib pkgs;
  });
}
