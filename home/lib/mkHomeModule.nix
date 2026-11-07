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
  # A link to a file that isn't in the repo would dangle, and the program
  # would run with no config and no error. So a missing file fails the build.
  mkSymlink =
    relativePath:
    lib.throwIfNot (builtins.pathExists (../programs + "/${name}/${relativePath}"))
      "dotfiles.programs.${name}: home/programs/${name}/${relativePath} does not exist"
      (
        config.lib.dotfiles.mkSymlinkFrom "${config.dotfiles.directory}/home/programs/${name}" relativePath
      );
in
{
  options.dotfiles.programs.${name}.enable = lib.mkEnableOption "Enable ${name} configuration.";

  config = lib.mkIf config.dotfiles.programs.${name}.enable (body (args // { inherit mkSymlink; }));
}
