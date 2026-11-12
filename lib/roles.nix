# What a host's roles are. The data check (./schema.nix) and the assembly
# (./default.nix) both read hosts through this, so they can't disagree.
{ lib }:
rec {
  # The OS a system runs, like "linux" for "x86_64-linux".
  osOf = system: (lib.systems.elaborate system).parsed.kernel.name;

  # The roles a host lists, plus its OS, so nobody has to list that one.
  rolesOf = host: lib.unique (host.roles ++ [ (osOf host.system) ]);

  # Every role a user file may name. "linux" and "darwin" always count, so a
  # user file doesn't break when the last Mac or Linux host goes.
  rolesAcross =
    hosts:
    lib.unique (
      [
        "linux"
        "darwin"
      ]
      ++ lib.concatMap rolesOf (lib.attrValues hosts)
    );
}
