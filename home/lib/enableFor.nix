# True when the host's name or one of its roles is in `names` (see
# config/hosts.nix). Two mistakes are errors, here and in disableFor, so
# neither can sit in a user file unnoticed:
#
# - a name that is neither a host nor a role (a typo);
# - a host this user has no home on. The user's file is never used there, so
#   naming it does nothing.
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
let
  list = lib.concatStringsSep ", ";

  # The hosts that don't list this user.
  hostsWithoutHome = lib.subtractLists homes hostNames;
in
names:
let
  unknown = lib.subtractLists knownNames names;
  homeless = lib.intersectLists hostsWithoutHome names;
in
lib.throwIf (unknown != [ ])
  "enableFor/disableFor: unknown host or role ${list unknown} (known: ${list knownNames})"
  (
    lib.throwIf (homeless != [ ])
      "enableFor/disableFor: ${list homeless} is a host where ${username} has no home, so naming it does nothing here (homes: ${list homes})"
      (lib.any (name: name == hostname || lib.elem name roles) names)
  )
