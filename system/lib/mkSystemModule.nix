{ name, folder }:
body:
{
  config,
  lib,
  # The module system only passes args a module names, and body needs pkgs.
  # deadnix: skip
  pkgs,
  ...
}@args:
let
  file = "${folder}/${name}.nix";

  # A module returns its system config and its `options`, the settings a host
  # file can set beside `enable` (see lib/moduleResult.nix).
  module = import ../../lib/moduleResult.nix { inherit lib; } {
    inherit file;
    owner = "dotfiles.modules.${name}";
    enable = "the ${name} system module";
  } (body args);
in
{
  _file = file;

  options.dotfiles.modules.${name} = module.options;

  config = lib.mkIf config.dotfiles.modules.${name}.enable module.config;
}
