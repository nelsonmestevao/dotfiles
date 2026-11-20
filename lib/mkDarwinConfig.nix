{
  nixpkgs,
  nix-darwin,
  pkgsFor,
}:
hostname:
{ host, users }:
let
  inherit (nixpkgs) lib;
  importModules = import ./importModules.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
in
nix-darwin.lib.darwinSystem {
  # `host` is this host's entry in config/hosts.nix; `users` holds the
  # config/users.nix entries of the users it lists.
  specialArgs = {
    inherit hostname host users;
  };
  modules = [
    {
      nixpkgs.hostPlatform = host.system;
      # The nixpkgs every config on this system shares (see ./default.nix).
      # It has the overlays and allows unfree packages.
      nixpkgs.pkgs = pkgsFor.${host.system};
    }
    ../system/darwin.nix
  ]
  ++ importModules mkSystemModule "system/modules/darwin";
}
