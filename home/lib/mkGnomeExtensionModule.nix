name: body:
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  mkSymlink = config.lib.dotfiles.mkSymlinkIn {
    owner = "dotfiles.programs.gnome.extensions.${name}";
    folder = "home/programs/gnome/extensions/${name}";
  };

  result = body (args // { inherit mkSymlink; });

  # Besides its config, an extension can return `package`, when it isn't
  # pkgs.gnomeExtensions.<name>, and `options`, its own settings (as in
  # mkHomeModule).
  package = result.package or pkgs.gnomeExtensions.${name};
  ownOptions = result.options or { };
  extensionConfig = removeAttrs result [
    "package"
    "options"
  ];

  uuid = package.extensionUuid;
in
{
  options.dotfiles.programs.gnome.extensions.${name} = ownOptions // {
    enable = lib.mkEnableOption "the ${name} GNOME extension";
  };

  config =
    lib.mkIf
      (config.dotfiles.programs.gnome.enable && config.dotfiles.programs.gnome.extensions.${name}.enable)
      (
        lib.mkMerge [
          {
            home.packages = [ package ];
            dotfiles.programs.gnome.enabledExtensions = [ uuid ];
            dotfiles.programs.gnome.extensionSchemaDirs = [
              "${package}/share/gnome-shell/extensions/${uuid}/schemas"
            ];
          }
          extensionConfig
        ]
      );
}
