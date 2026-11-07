{
  nixpkgs,
  home-manager,
  vicinae,
  overlays,
  knownNames,
}:
system: hostname: roles: username: cfg:
let
  lib = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.${system};
  importModules = import ./importModules.nix { inherit lib; };
  mkHomeModule = import ../home/lib/mkHomeModule.nix;
  mkGnomeExtensionModule = import ../home/lib/mkGnomeExtensionModule.nix;

  # What enableFor/disableFor need to know about this host.
  hostInfo = {
    inherit
      lib
      hostname
      roles
      knownNames
      ;
  };
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = {
    inherit username hostname;
    enableFor = import ../home/lib/enableFor.nix hostInfo;
    disableFor = import ../home/lib/disableFor.nix hostInfo;
  }
  // (cfg.extraSpecialArgs or { });
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
