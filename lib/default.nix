# Assembly: turns the data in `config/` into the flake's configuration outputs.
{
  nixpkgs,
  home-manager,
  nix-darwin,
  vicinae,
  hosts,
  users,
  overlays,
}:
let
  lib = nixpkgs.lib;

  # ── Builders ───────────────────────────────────────────────────────────────

  # Keyed by the host's `platform`, so the filter and the builder can't diverge.
  builders = {
    nixos = import ./mkNixosConfig.nix { inherit nixpkgs vicinae overlays; };
    darwin = import ./mkDarwinConfig.nix { inherit nixpkgs nix-darwin overlays; };
  };

  mkHomeConfig = import ./mkHomeConfig.nix {
    inherit
      nixpkgs
      home-manager
      vicinae
      overlays
      knownNames
      ;
  };

  # ── Helpers ────────────────────────────────────────────────────────────────

  # A host's roles: the ones it lists, plus its OS kernel ("linux" or
  # "darwin"), read from `system`. Home-only hosts get it too. Listing the
  # OS role by hand is harmless, since duplicates are dropped.
  rolesOf =
    hostCfg:
    lib.unique (
      (hostCfg.roles or [ ]) ++ [ (lib.systems.elaborate hostCfg.system).parsed.kernel.name ]
    );

  # Every host name and role that enableFor/disableFor accept. A role named
  # like a host would make `enableFor [ "x" ]` ambiguous, so that's an error.
  # "linux" and "darwin" always count, even with no host on that OS, so a
  # user file doesn't break when you remove your last Mac or Linux host.
  knownNames =
    let
      hostNames = lib.attrNames hosts;
      roles = lib.unique (
        [
          "linux"
          "darwin"
        ]
        ++ lib.concatMap rolesOf (lib.attrValues hosts)
      );
      clashes = lib.intersectLists hostNames roles;
    in
    lib.throwIf (clashes != [ ])
      "config/hosts.nix: role ${lib.concatStringsSep ", " clashes} has the same name as a host"
      (hostNames ++ roles);

  # Hosts list their users by name; system builders want the definitions too.
  # { users = [ "nelson" ]; ... } -> { host = <the entry>; users = { nelson = <user definition>; }; }
  withUsers = cfg: {
    host = cfg;
    users = lib.genAttrs cfg.users (u: users.${u});
  };

  # "username@hostname" -> home-manager configuration.
  mkHomeEntry =
    hostname: hostCfg: username:
    lib.nameValuePair "${username}@${hostname}" (mkHomeConfig {
      inherit hostname username;
      host = hostCfg;
      roles = rolesOf hostCfg;
      user = users.${username};
    });

  # Platform names are matched loosely, so `" NixOS "` still resolves.
  # Applied to both sides of the comparison, never to what the user sees.
  normalizePlatform = p: lib.toLower (lib.trim p);
in
{
  # Every system targeted by at least one host.
  allSystems = lib.unique (lib.mapAttrsToList (_: h: h.system) hosts);

  # Hosts declaring this `platform`, each built by that platform's builder.
  # Names are normalized on both sides (see `normalizePlatform`). The guard is
  # what makes a misspelled platform fail loudly: without it the filter just
  # yields no hosts, and `mapAttrs` never forces the missing builder, so you'd
  # get a silently empty attrset instead of an error.
  systemConfigsFor =
    platform:
    let
      key = normalizePlatform platform;
    in
    lib.throwIfNot (builders ? ${key})
      "systemConfigsFor: unknown platform \"${platform}\" (known: ${lib.concatStringsSep ", " (lib.attrNames builders)})"
      (
        lib.mapAttrs builders.${key} (
          lib.mapAttrs (_: withUsers) (
            lib.filterAttrs (_: cfg: normalizePlatform (cfg.platform or "") == key) hosts
          )
        )
      );

  # Every "username@hostname" pair across all hosts.
  homeConfigs = lib.concatMapAttrs (
    hostname: hostCfg: lib.listToAttrs (map (mkHomeEntry hostname hostCfg) hostCfg.users)
  ) hosts;
}
