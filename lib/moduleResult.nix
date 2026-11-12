# What a module body returned, checked for the wrappers (mkHomeModule,
# mkGnomeExtensionModule, mkSystemModule).
#
# A module returns a plain attribute set: its config, plus `options` for the
# settings it declares. Two mistakes would otherwise pass in silence:
#
# - The whole body wrapped in lib.mkIf, lib.mkMerge or the like. The wrapper
#   can't see `options` inside it, so the settings would never be declared.
# - A setting named `enable`. The wrapper owns that name and would drop it.
#
# `owner` is the module's option and `file` its path from the repo root. Both
# go in the message.
{ lib }:
{ owner, file }:
result:
lib.throwIf (result ? _type)
  "${owner}: ${file} must return a plain attribute set, but its whole body is wrapped in lib.mkIf, lib.mkMerge or the like. Put lib.mkIf on single values inside it."
  (
    lib.throwIf ((result.options or { }) ? enable)
      "${owner}: ${file} declares options.enable, but the wrapper already adds `enable`. Give the setting another name."
      result
  )
