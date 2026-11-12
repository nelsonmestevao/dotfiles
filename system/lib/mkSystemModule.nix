name: body:
{
  config,
  lib,
  # The module system only passes args a module names, and body needs pkgs.
  # deadnix: skip
  pkgs,
  ...
}@args:
let
  moduleResult = import ../../lib/moduleResult.nix { inherit lib; };

  # NixOS and nix-darwin modules share this wrapper, so the message can't say
  # which of the two folders the file is in.
  result = moduleResult {
    owner = "dotfiles.modules.${name}";
    file = "system/modules/<nixos|darwin>/${name}/${name}.nix";
  } (body args);

  # Besides its system config, a module can return `options`: the settings a
  # host file can set beside `enable`. They are declared even while the module
  # is off, so a host file can always set them.
  ownOptions = result.options or { };
  systemConfig = removeAttrs result [ "options" ];
in
{
  options.dotfiles.modules.${name} = ownOptions // {
    enable = lib.mkEnableOption "the ${name} system module";
  };

  config = lib.mkIf config.dotfiles.modules.${name}.enable systemConfig;
}
