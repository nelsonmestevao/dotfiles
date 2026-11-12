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
  result = body args;

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
