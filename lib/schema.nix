# Checks `config/hosts.nix` and `config/users.nix` before a configuration is
# built, and fills in the fields an entry leaves out.
#
# Both files are plain data, so a typo used to pass without a word: a host
# with `rolse = [ "desktop" ]` just lost its desktop programs. Now a mistake
# stops the evaluation and names the host or user and the field. The check has
# two steps:
#
# 1. Types. Every field is an option below, so the module system rejects a
#    field that doesn't exist, a missing one, and a value of the wrong kind.
#    It stops at the first one.
# 2. Rules, for what a type can't say: how fields, entries and files fit
#    together. Every broken rule is listed, in one message.
#
# To add a field, add its option. Add a rule only when the field has to agree
# with something else.
{ lib }:
let
  inherit (lib) mkOption types;
  inherit (import ./roles.nix { inherit lib; }) osOf rolesAcross;

  # ── Types ──────────────────────────────────────────────────────────────────

  # The systems nixpkgs supports in flakes. A host's `system` must be one of
  # them, and `systemsIn` below skips any other.
  systems = lib.systems.flakeExposed;

  # The OS each platform's system has to run.
  osFor = {
    nixos = "linux";
    darwin = "darwin";
  };

  # A list of words that names none twice.
  distinctWords =
    list:
    types.addCheck list lib.allUnique // { description = "${list.description}, each listed once"; };

  hostFields = {
    system = mkOption {
      type = types.enum systems;
      description = "The Nix system the host runs, like \"x86_64-linux\".";
    };
    platform = mkOption {
      type = types.nullOr (types.enum (lib.attrNames osFor));
      default = null;
      description = "What builds the system. Left out, the host only gets a home.";
    };
    roles = mkOption {
      type = distinctWords (types.listOf types.str);
      default = [ ];
      description = "What the host is for, like \"desktop\". User files turn programs on by role.";
    };
    users = mkOption {
      type = distinctWords (types.nonEmptyListOf types.str);
      description = "The users from config/users.nix that get a home here.";
    };
    stateVersion = mkOption {
      type = types.strMatching "[0-9]{2}\\.[0-9]{2}";
      description = "The release the host was first installed with, like \"26.05\".";
    };
    darwinStateVersion = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = "The nix-darwin version a Mac was first installed with, like 6.";
    };
  };

  userFields = {
    name = mkOption {
      type = types.str;
      description = "The user's full name.";
    };
    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Groups for the account on NixOS, like \"wheel\".";
    };
    extraSpecialArgs = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
      description = "Extra arguments for the user's home modules.";
    };
  };

  entriesWith = fields: mkOption { type = types.attrsOf (types.submodule { options = fields; }); };

  # Both files through the module system, with every field read: a type is
  # only checked when its value is read, so a mistake in a field nothing uses
  # yet still stops the build. The values of `extraSpecialArgs` are left
  # alone, since they can be anything, even a whole package set.
  typed =
    { hosts, users }:
    let
      evaluated = lib.evalModules {
        modules = [
          {
            options.hosts = entriesWith hostFields;
            options.users = entriesWith userFields;
          }
          {
            _file = "config/hosts.nix";
            inherit hosts;
          }
          {
            _file = "config/users.nix";
            inherit users;
          }
        ];
      };
      data = { inherit (evaluated.config) hosts users; };
      argumentNames = user: user // { extraSpecialArgs = lib.attrNames user.extraSpecialArgs; };
    in
    builtins.deepSeq (data // { users = lib.mapAttrs (_: argumentNames) data.users; }) data;

  # ── Rules ──────────────────────────────────────────────────────────────────
  # Each rule gives one sentence for every place the data breaks it.

  inEach = entries: sentencesFor: lib.concatLists (lib.mapAttrsToList sentencesFor entries);

  unknownUsers =
    { hosts, users, ... }:
    inEach hosts (
      name: host:
      map (
        user:
        "config/hosts.nix: ${name}.users has \"${user}\", which is not in config/users.nix (known: ${lib.concatStringsSep ", " (lib.attrNames users)})"
      ) (lib.subtractLists (lib.attrNames users) host.users)
    );

  platformsOnTheWrongOs =
    { hosts, ... }:
    inEach hosts (
      name: host:
      lib.optional (host.platform != null && osFor.${host.platform} != osOf host.system)
        "config/hosts.nix: ${name}.platform is \"${host.platform}\", which needs a ${osFor.${host.platform}} system, but ${name}.system is \"${host.system}\""
    );

  macsWithoutAStateVersion =
    { hosts, ... }:
    inEach hosts (
      name: host:
      lib.optional (host.platform == "darwin" && host.darwinStateVersion == null)
        "config/hosts.nix: ${name} is a Mac, so it needs `darwinStateVersion`: the nix-darwin version it was first installed with, like 6"
    );

  # A role named like a host would make `enableFor [ "x" ]` mean two things.
  rolesNamedLikeAHost =
    { hosts, ... }:
    map (
      name:
      "config/hosts.nix: \"${name}\" is both a host and a role, so `enableFor` could not tell them apart"
    ) (lib.intersectLists (rolesAcross hosts) (lib.attrNames hosts));

  # A user's own argument by one of these names would replace it, and break
  # modules far from the mistake. The module system and Home Manager pass the
  # last few on their own.
  argumentsTheModulesAlreadyGet =
    { users, ... }:
    let
      taken = import ./homeArguments.nix ++ [
        "lib"
        "pkgs"
        "config"
        "options"
        "modulesPath"
        "osConfig"
      ];
    in
    inEach users (
      name: user:
      map (
        argument:
        "config/users.nix: ${name}.extraSpecialArgs can't use \"${argument}\": the home modules already get an argument by that name"
      ) (lib.intersectLists taken (lib.attrNames user.extraSpecialArgs))
    );

  # Without these files the build fails later, on a bare import.
  missingFiles =
    {
      hosts,
      users,
      root,
    }:
    let
      needs =
        file: name: path:
        lib.optional (!builtins.pathExists (root + "/${path}"))
          "${file}: ${name} needs ${path}, which does not exist (`git add` a new file, or the flake can't see it)";
    in
    inEach users (name: _: needs "config/users.nix" name "home/users/${name}.nix")
    ++ inEach hosts (
      name: host:
      lib.optionals (host.platform != null) (needs "config/hosts.nix" name "system/hosts/${name}.nix")
      ++ lib.optionals (host.platform == "nixos") (
        needs "config/hosts.nix" name "system/hosts/${name}/hardware.nix"
      )
    );

  rules = [
    unknownUsers
    platformsOnTheWrongOs
    macsWithoutAStateVersion
    rolesNamedLikeAHost
    argumentsTheModulesAlreadyGet
    missingFiles
  ];

  # What the rules find, one sentence each. `root` is the repository the data
  # describes; the rules look for its files there.
  problemsIn = checked: root: lib.concatMap (rule: rule (checked // { inherit root; })) rules;
in
{
  # The data with every field filled in, or an error that says what is wrong.
  check =
    {
      hosts,
      users,
      root,
    }:
    let
      checked = typed { inherit hosts users; };
      found = problemsIn checked root;
    in
    lib.throwIf (found != [ ]) (lib.concatStringsSep "\n" found) checked;

  # What the rules say, for the tests: the text of an error can't be read back.
  problems =
    {
      hosts,
      users,
      root,
    }:
    problemsIn (typed { inherit hosts users; }) root;

  # The systems the hosts run, read without checking anything else, for the
  # outputs that have to work while the data is wrong.
  systemsIn =
    hosts:
    lib.unique (
      lib.filter (system: lib.elem system systems) (
        map (host: host.system or null) (lib.filter lib.isAttrs (lib.attrValues hosts))
      )
    );
}
