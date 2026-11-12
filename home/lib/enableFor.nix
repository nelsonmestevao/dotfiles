# True when the host's name or one of its roles is in `names` (see
# config/hosts.nix). Two mistakes are errors, so neither can quietly turn a
# program off:
#
# - a name that is neither a host nor a role (a typo);
# - a host this user has no home on (the line could never be true).
#
# Roles stay open: a user file may name a role that none of its hosts has yet.
{
  lib,
  hostname,
  roles,
  knownNames,
  hostNames,
  username,
  homes,
}:
names:
let
  list = lib.concatStringsSep ", ";

  unknown = lib.subtractLists knownNames names;
  # The hosts in `names` that don't list this user.
  homeless = lib.intersectLists (lib.subtractLists homes hostNames) names;
in
lib.throwIf (unknown != [ ])
  "enableFor/disableFor: unknown host or role ${list unknown} (known: ${list knownNames})"
  (
    lib.throwIf (homeless != [ ])
      "enableFor/disableFor: ${username} has no home on ${list homeless} (homes: ${list homes})"
      (lib.any (name: name == hostname || lib.elem name roles) names)
  )
