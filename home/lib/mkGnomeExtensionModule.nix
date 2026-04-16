{ lib }:
name: body:
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  mkSymlink =
    relativePath:
    config.lib.dotfiles.mkSymlinkFrom "${config.dotfiles.directory}/home/programs/gnome/extensions/${name}" relativePath;

  bodyResult = body (args // { inherit mkSymlink; });
  package = bodyResult.package or pkgs.gnomeExtensions.${name};
  uuid = package.extensionUuid;
  userConfig = removeAttrs bodyResult [ "package" ];
in
{
  options.dotfiles.programs.gnome.extensions.${name}.enable =
    lib.mkEnableOption "Enable ${name} GNOME extension.";

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
          userConfig
        ]
      );
}
