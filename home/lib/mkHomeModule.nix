name: body:
{
  config,
  lib,
  # The module system only passes args a module names, and body needs pkgs.
  # deadnix: skip
  pkgs,
  hostname,
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

  result = body (args // { inherit mkSymlink; });

  # A module that only runs on one OS says so with `platforms = [ "linux" ]`
  # or `[ "darwin" ]`. Enabling it on the other OS is an error with the host's
  # name in it, instead of a failure deep inside a package build.
  platforms = result.platforms or null;
  settings = removeAttrs result [ "platforms" ];
  platform = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  supported = platforms == null || lib.elem platform platforms;

  enabled = config.dotfiles.programs.${name}.enable;
in
{
  options.dotfiles.programs.${name}.enable = lib.mkEnableOption "Enable ${name} configuration.";

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = enabled -> supported;
          message = "dotfiles.programs.${name} only runs on ${
            lib.concatStringsSep " and " (if platforms == null then [ ] else platforms)
          }, but it's enabled on ${hostname} (${platform}).";
        }
      ];
    }
    (lib.mkIf (enabled && supported) settings)
  ];
}
