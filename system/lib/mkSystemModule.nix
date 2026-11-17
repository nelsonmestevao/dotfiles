# `file` is where the module is, from the repo root, for messages.
{ name, file }:
body:
# body gets every module arg it names, like pkgs (see lib/takesArgsOf.nix).
import ../../lib/takesArgsOf.nix body (
  { config, lib, ... }@args:
  let
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
)
