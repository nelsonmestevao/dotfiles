{ lib, ... }:
{
  options.dotfiles.programs.gnome = {
    enabledExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "UUIDs of enabled GNOME extensions, aggregated from per-extension modules.";
    };

    extensionSchemaDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "GSettings schema directories contributed by per-extension modules.";
    };
  };
}
