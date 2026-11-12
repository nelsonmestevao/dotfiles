# Picks this host's value from `choices`, a set keyed by host names and roles,
# the same names enableFor takes. A host name beats a role, and a role beats
# `default`. With no match and no `default`, the value is null.
#
# Every key gets enableFor's checks, so a typo, or a host this user has no
# home on, stops the build. Unlike an `if enableFor … else if …` chain, which
# stops at the first match, this checks every key on every host. Two of the
# host's roles with different values stop the build too, since neither one
# clearly wins: name the host to pick one.
{
  lib,
  hostname,
  roles,
  ...
}@hostInfo:
let
  enableFor = import ./enableFor.nix hostInfo;
in
choices:
let
  named = removeAttrs choices [ "default" ];
  matchedRoles = lib.filter (role: named ? ${role}) roles;
  roleValues = lib.unique (map (role: named.${role}) matchedRoles);
in
# enableFor runs only for its checks. Which key wins is decided below.
builtins.seq (enableFor (lib.attrNames named)) (
  named.${hostname} or (
    if lib.length roleValues > 1 then
      throw "valueFor: ${hostname} has roles ${lib.concatStringsSep ", " matchedRoles} with different values. Name ${hostname} to pick one."
    else if roleValues != [ ] then
      lib.head roleValues
    else
      choices.default or null
  )
)
