{
  nixpkgs,
  home-manager,
  vicinae,
}:
system: hostname: username: cfg:
let
  lib = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.${system};
  mkHomeModule = import ../home/lib/mkHomeModule.nix { inherit lib; };
  homeModules = map (name: mkHomeModule name (import ../home/programs/${name}/${name}.nix)) (
    lib.attrNames (builtins.readDir ../home/programs)
  );

  mkGnomeExtensionModule = import ../home/lib/mkGnomeExtensionModule.nix { inherit lib; };
  gnomeExtensionsDir = ../home/programs/gnome/extensions;
  gnomeExtensionModules = map (
    name: mkGnomeExtensionModule name (import "${gnomeExtensionsDir}/${name}/${name}.nix")
  ) (lib.attrNames (builtins.readDir gnomeExtensionsDir));
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = {
    inherit username hostname;
  }
  // (cfg.extraSpecialArgs or { });
  modules = [
    { nixpkgs.overlays = cfg.overlays or [ ]; }
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
  ++ homeModules
  ++ gnomeExtensionModules;
}
