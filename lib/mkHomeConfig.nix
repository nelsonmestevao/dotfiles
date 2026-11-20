{
  inputs,
  pkgsFor,
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
  inherit (inputs.nixpkgs) lib;
  pkgs = pkgsFor.${host.system};
  importModules = import ./importModules.nix { inherit lib; };
  mkHomeModule = import ../home/lib/mkHomeModule.nix;
  plainPrograms = import ../home/lib/plainPrograms.nix { inherit lib pkgs; };
  gnomeExtensions = import ../home/lib/gnomeExtensions.nix { inherit lib pkgs; };

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
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = arguments;
  modules = [
    # Home Manager loads a nixpkgs of its own for each home, even when it is
    # handed one. This makes every module use the shared one (see `pkgsFor`
    # in ./default.nix), which has the overlays and allows unfree packages.
    { _module.args.pkgs = lib.mkForce pkgs; }
    ../home
    ../home/lib
    # Every module is imported on every OS, the Linux-only ones too (vicinae,
    # the GNOME extensions). A module that is off does nothing, but its
    # options must exist, or a user file that sets one fails on a Mac.
    inputs.vicinae.homeManagerModules.default
  ]
  ++ importModules mkHomeModule "home/programs"
  ++ plainPrograms
  ++ gnomeExtensions;
}
