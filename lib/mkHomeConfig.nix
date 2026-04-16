{
  nixpkgs,
  home-manager,
}:
system: hostname: username: cfg:
let
  lib = nixpkgs.lib;
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
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = {
    inherit username hostname;
  }
  // (cfg.extraSpecialArgs or { });
  modules = [
    { nixpkgs.overlays = cfg.overlays or [ ]; }
    ../home
    ../home/lib
  ]
  ++ homeModules
  ++ gnomeExtensionModules;
}
