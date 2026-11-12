# Turns the data in `config/` into the flake's configurations.
{
  nixpkgs,
  home-manager,
  nix-darwin,
  vicinae,
  hosts,
  users,
  overlays,
  # The repository the data describes. Only the tests point it at a fixture.
  root ? ../.,
}:
let
  inherit (nixpkgs) lib;
  inherit (import ./roles.nix { inherit lib; }) rolesOf rolesAcross;

  # ── Data ───────────────────────────────────────────────────────────────────

  # The host and user entries, checked (see ./schema.nix), with every field
  # filled in. A mistake stops every configuration here and says what it is.
  checked = (import ./schema.nix { inherit lib; }).check { inherit hosts users root; };

  hostNames = lib.attrNames checked.hosts;

  # Every host name and role that enableFor, disableFor and valueFor accept.
  knownNames = hostNames ++ rolesAcross checked.hosts;

  # The hosts that list a user: the ones the user has a home on.
  homesOf =
    username: lib.attrNames (lib.filterAttrs (_: host: lib.elem username host.users) checked.hosts);

  # ── Configurations ─────────────────────────────────────────────────────────

  builders = {
    nixos = import ./mkNixosConfig.nix { inherit nixpkgs vicinae overlays; };
    darwin = import ./mkDarwinConfig.nix { inherit nixpkgs nix-darwin overlays; };
  };

  # The hosts with this `platform`, each with its users' entries.
  systemsOn =
    platform:
    lib.mapAttrs (
      hostname: host:
      builders.${platform} hostname {
        inherit host;
        users = lib.getAttrs host.users checked.users;
      }
    ) (lib.filterAttrs (_: host: host.platform == platform) checked.hosts);

  mkHomeConfig = import ./mkHomeConfig.nix {
    inherit
      nixpkgs
      home-manager
      vicinae
      overlays
      knownNames
      hostNames
      ;
  };

  # "username@hostname" -> home-manager configuration.
  homeOf =
    hostname: host: username:
    lib.nameValuePair "${username}@${hostname}" (mkHomeConfig {
      inherit hostname host username;
      roles = rolesOf host;
      homes = homesOf username;
      user = checked.users.${username};
    });
in
{
  nixosConfigs = systemsOn "nixos";
  darwinConfigs = systemsOn "darwin";
  homeConfigs = lib.concatMapAttrs (
    hostname: host: lib.listToAttrs (map (homeOf hostname host) host.users)
  ) checked.hosts;

  # The systems the hosts run, for the dev shell, the formatter and the
  # checks. They are read from the data as it is written, skipping a host
  # whose system can't be used: every bin/ script starts in the dev shell, so
  # it has to open while a mistake in the data is being fixed.
  allSystems = lib.unique (
    lib.concatMap (
      host:
      lib.optional (
        lib.isAttrs host && lib.elem (host.system or null) lib.systems.flakeExposed
      ) host.system
    ) (lib.attrValues hosts)
  );
}
