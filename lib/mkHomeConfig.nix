{
  nixpkgs,
  home-manager,
  vicinae,
  overlays,
  knownNames,
  hosts,
}:
{
  hostname,
  host,
  roles,
  username,
  user,
}:
let
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.${host.system};
  importModules = import ./importModules.nix { inherit lib; };
  mkHomeModule = import ../home/lib/mkHomeModule.nix;
  mkGnomeExtensionModule = import ../home/lib/mkGnomeExtensionModule.nix;

  # What enableFor/disableFor need to know about this host and this user.
  hostInfo = {
    inherit
      lib
      hostname
      roles
      knownNames
      username
      ;
    hostNames = lib.attrNames hosts;
    # The hosts that list this user: the ones the user has a home on.
    homes = lib.attrNames (lib.filterAttrs (_: h: lib.elem username h.users) hosts);
  };
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  # `host` and `user` are the entries from config/hosts.nix and
  # config/users.nix, so a module can read a host fact (the state version)
  # without knowing the host's name.
  extraSpecialArgs = {
    inherit
      username
      hostname
      host
      user
      ;
    enableFor = import ../home/lib/enableFor.nix hostInfo;
    disableFor = import ../home/lib/disableFor.nix hostInfo;
  }
  // (user.extraSpecialArgs or { });
  modules = [
    { nixpkgs.overlays = overlays; }
    ../home
    ../home/lib
    # Always import every module so its options are *declared* on every
    # platform. GNOME extensions and Vicinae are Linux/Wayland-only, but their
    # activation is already gated by per-program `enable` flags (off on Darwin),
    # and module `config` blocks / option defaults are lazy `mkIf`-guarded — so
    # importing them on Darwin evaluates cleanly and activates nothing. Gating
    # the *imports* instead would drop the option declarations, which breaks
    # any `mkIf false` reference to them (the module system checks definition
    # paths against declarations regardless of the condition).
    vicinae.homeManagerModules.default
  ]
  ++ importModules mkHomeModule ../home/programs
  ++ importModules mkGnomeExtensionModule ../home/programs/gnome/extensions;
}
