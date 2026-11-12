# Splits what a module body returned, for the wrappers (mkHomeModule,
# mkGnomeExtensionModule, mkSystemModule).
#
# A body returns a plain attribute set: its config, plus `options` for the
# settings it declares, plus the `reserved` keys its wrapper reads itself (like
# `platforms`). This gives back `options`, the settings with `enable` added,
# and `config`, the rest. The settings are declared even while the module is
# off, so a user or host file can always set them.
#
# Two mistakes stop the build here, with a message that names the module and
# the fix:
#
# - The whole body wrapped in lib.mkIf, lib.mkMerge or the like. The wrapper
#   can't see `options` inside it.
# - A setting named `enable`. The wrapper owns that name.
#
# `owner` is the module's option and `file` its path from the repo root. Both
# go in the message. `enable` is the text of the `enable` option.
{ lib }:
{
  owner,
  file,
  enable,
  reserved ? [ ],
}:
result:
let
  checked =
    lib.throwIf (result ? _type)
      "${owner}: ${file} must return a plain attribute set, but its whole body is wrapped in lib.mkIf, lib.mkMerge or the like. Put lib.mkIf on single values inside it."
      (
        lib.throwIf ((result.options or { }) ? enable)
          "${owner}: ${file} declares options.enable, but the wrapper already adds `enable`. Give the setting another name."
          result
      );
in
{
  options = (checked.options or { }) // {
    enable = lib.mkEnableOption enable;
  };
  config = removeAttrs checked ([ "options" ] ++ reserved);
}
