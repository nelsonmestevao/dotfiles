{ name, folder }:
body:
{
  config,
  lib,
  # The module system only passes args a module names, and body needs pkgs.
  pkgs,
  hostname,
  ...
}@args:
let
  owner = "dotfiles.programs.${name}";
  file = "${folder}/${name}.nix";

  mkSymlink = config.lib.dotfiles.mkSymlinkIn { inherit owner folder; };

  result = body (args // { inherit mkSymlink; });

  # Besides its Home Manager config and its `options` (see
  # lib/moduleResult.nix), a module can return `platforms`, when it only runs
  # on one OS: `[ "linux" ]` or `[ "darwin" ]`. Enabling it on the other OS is
  # an error with the host's name in it, instead of a failure deep inside a
  # package build.
  module = import ../../lib/moduleResult.nix { inherit lib; } {
    inherit owner file;
    enable = "the ${name} program";
    reserved = [ "platforms" ];
  } result;
  platforms = result.platforms or null;

  platform = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  supported = platforms == null || lib.elem platform platforms;

  enabled = config.dotfiles.programs.${name}.enable;
in
{
  _file = file;

  options.dotfiles.programs.${name} = module.options;

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
    (lib.mkIf (enabled && supported) module.config)
  ];
}
