name: body:
{
  config,
  lib,
  # The module system only passes args a module names, and body needs pkgs.
  # deadnix: skip
  pkgs,
  ...
}@args:
{
  options.dotfiles.modules.${name}.enable = lib.mkEnableOption "Enable ${name} system configuration.";

  config = lib.mkIf config.dotfiles.modules.${name}.enable (body args);
}
