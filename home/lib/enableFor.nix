# True when the host's name or one of its roles is in `names` (see
# config/hosts.nix). A name that is neither a host nor a role is an error, so a
# typo can't quietly turn a program off.
{
  lib,
  hostname,
  roles,
  knownNames,
}:
names:
let
  unknown = lib.subtractLists knownNames names;
in
lib.throwIf (unknown != [ ])
  "enableFor/disableFor: unknown host or role ${lib.concatStringsSep ", " unknown} (known: ${lib.concatStringsSep ", " knownNames})"
  (lib.any (name: name == hostname || lib.elem name roles) names)
