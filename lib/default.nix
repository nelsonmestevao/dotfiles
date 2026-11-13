# Turns the data in `config/` into the flake's configurations.
{
  nixpkgs,
  home-manager,
  nix-darwin,
  vicinae,
  hosts,
  users,
  overlays,
  # Where the repo is. Only the tests point it elsewhere, at a small sample.
  root ? ../.,
}:
let
  inherit (nixpkgs) lib;
  inherit (import ./roles.nix { inherit lib; }) rolesOf rolesAcross;
  schema = import ./schema.nix { inherit lib; };

  # ── Data ───────────────────────────────────────────────────────────────────

  # The host and user entries, checked (see ./schema.nix), with every field
  # filled in. A mistake stops every configuration here and says what it is.
  checked = schema.check { inherit hosts users root; };

  # True when the data has no mistake. The checks use it to tell a mistake in
  # the data from an error inside one configuration.
  dataIsRight = (builtins.tryEval checked).success;

  toolSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

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

  # The checked data, for the checks (see ./checks.nix).
  checkedData = checked;
  inherit dataIsRight;

  # The systems the dev shell and the formatter are made for: the ones
  # bin/setup offers. They don't depend on the data, so a mistake in it can't
  # take them away. Every bin/ script starts in the dev shell.
  inherit toolSystems;

  # The systems the hosts run, for the checks and the packages. With a mistake
  # in the data, all four above, so the check that reports the mistake shows
  # up on every machine.
  hostSystems =
    if dataIsRight then
      lib.unique (lib.mapAttrsToList (_: host: host.system) checked.hosts)
    else
      toolSystems;
}
