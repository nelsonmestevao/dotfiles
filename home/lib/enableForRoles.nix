# True when the host has any of the `wanted` roles (see config/hosts.nix). A
# role no host declares is an error, so a typo can't quietly turn a program off.
{
  lib,
  roles,
  knownRoles,
}:
wanted:
let
  unknown = lib.subtractLists knownRoles wanted;
in
lib.throwIf (unknown != [ ])
  "enableForRoles: unknown role ${lib.concatStringsSep ", " unknown} (known: ${lib.concatStringsSep ", " knownRoles})"
  (lib.any (role: lib.elem role roles) wanted)
