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
  mkSymlink = config.lib.dotfiles.mkSymlinkIn {
    owner = "dotfiles.programs.${name}";
    folder = "home/programs/${name}";
  };

  result = body (args // { inherit mkSymlink; });

  # Besides its Home Manager config, a module can return two things.
  #
  # `platforms`, when it only runs on one OS: `[ "linux" ]` or `[ "darwin" ]`.
  # Enabling it on the other OS is an error with the host's name in it,
  # instead of a failure deep inside a package build.
  #
  # `options`, the settings a user file can set beside `enable`, like
  # `dotfiles.programs.zsh.showHost`. They are declared even while the program
  # is off, so a user file can always set them.
  platforms = result.platforms or null;
  ownOptions = result.options or { };
  homeConfig = removeAttrs result [
    "platforms"
    "options"
  ];

  platform = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  supported = platforms == null || lib.elem platform platforms;

  enabled = config.dotfiles.programs.${name}.enable;
in
{
  options.dotfiles.programs.${name} = ownOptions // {
    enable = lib.mkEnableOption "the ${name} program";
  };

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
    (lib.mkIf (enabled && supported) homeConfig)
  ];
}
