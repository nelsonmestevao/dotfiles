{
  nixpkgs,
  home-manager,
  mkHomeModules,
}:
system: hostname: username: cfg:
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
  ++ mkHomeModules;
}
