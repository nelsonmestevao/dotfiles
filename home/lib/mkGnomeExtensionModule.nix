# `file` is where the module is, from the repo root, for messages.
{ name, file }:
body:
{
  config,
  lib,
  pkgs,
  # The module system only passes args a module names, and body needs this
  # one (see home/lib/default.nix).
  # deadnix: skip
  mkSymlink,
  ...
}@args:
let
  owner = "dotfiles.programs.gnome.extensions.${name}";

  result = body args;

  # Besides its config and its `options` (see lib/moduleResult.nix), an
  # extension can return `package`, when it isn't pkgs.gnomeExtensions.<name>.
  module = import ../../lib/moduleResult.nix { inherit lib; } {
    inherit owner file;
    enable = "the ${name} GNOME extension";
    reserved = [ "package" ];
  } result;
  package = result.package or pkgs.gnomeExtensions.${name};

  uuid = package.extensionUuid;
in
{
  _file = file;

  options.dotfiles.programs.gnome.extensions.${name} = module.options;

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
          module.config
        ]
      );
}
