{
  nixpkgs,
  home-manager,
  mkHomeModules,
}:
system: username: cfg:
home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = {
    inherit username;
  }
  // (cfg.extraSpecialArgs or { });
  modules = [
    { nixpkgs.overlays = cfg.overlays or [ ]; }
    ../home
    ../home/lib
  ]
  ++ mkHomeModules;
}
