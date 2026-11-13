{
  nixpkgs,
  home-manager,
  overlays,
  knownNames,
  hostNames,
}:
{
  hostname,
  host,
  roles,
  homes,
  username,
  user,
}:
let
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.${host.system};
  importModules = import ./importModules.nix { inherit lib; };
  mkHomeModule = import ../home/lib/mkHomeModule.nix;
  mkGnomeExtensionModule = import ../home/lib/mkGnomeExtensionModule.nix;

  # What enableFor, disableFor and valueFor need to know about this host and
  # this user.
  hostInfo = {
    inherit
      lib
      hostname
      roles
      knownNames
      hostNames
      username
      homes
      ;
  };

  # What every home module gets. `host` and `user` are the entries from
  # config/hosts.nix and config/users.nix, so a module can read a host fact
  # (the state version) without knowing the host's name.
  arguments = {
    inherit
      username
      hostname
      host
      user
      ;
    enableFor = import ../home/lib/enableFor.nix hostInfo;
    disableFor = import ../home/lib/disableFor.nix hostInfo;
    valueFor = import ../home/lib/valueFor.nix hostInfo;
  };

  # The schema keeps a user's own `extraSpecialArgs` off the names in
  # ./homeArguments.nix, so that list must be exactly these arguments.
  listed = import ./homeArguments.nix;
  passed = lib.attrNames arguments;
  notListed = lib.subtractLists listed passed;
  notPassed = lib.subtractLists passed listed;
  sameAsListed =
    lib.throwIf (notListed ++ notPassed != [ ])
      "lib/homeArguments.nix must list the arguments lib/mkHomeConfig.nix passes. Not listed: ${toString notListed}. Listed but not passed: ${toString notPassed}."
      arguments;
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = sameAsListed // user.extraSpecialArgs;
  modules = [
    { nixpkgs.overlays = overlays; }
    ../home
    ../home/lib
  ]
  # Every module is loaded on every OS, the Linux-only ones too, so a user file
  # can set its options anywhere. A module only does something where it is on.
  ++ importModules mkHomeModule "home/programs"
  ++ importModules mkGnomeExtensionModule "home/programs/gnome/extensions";
}
