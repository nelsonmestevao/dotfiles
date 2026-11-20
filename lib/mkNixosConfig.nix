{ inputs, pkgsFor }:
hostname:
{ host, users }:
let
  inherit (inputs.nixpkgs) lib;
  importModules = import ./importModules.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
in
lib.nixosSystem {
  inherit (host) system;
  # `host` is this host's entry in config/hosts.nix; `users` holds the
  # config/users.nix entries of the users it lists.
  specialArgs = {
    inherit hostname host users;
  };
  modules = [
    # The nixpkgs every config on this system shares (see ./default.nix). It
    # has the overlays and allows unfree packages.
    { nixpkgs.pkgs = pkgsFor.${host.system}; }
    ../system/nixos.nix
    inputs.vicinae.nixosModules.default
    (
      { config, pkgs, ... }:
      {
        # Gate upstream's input-server (default: true) on our per-host flag.
        programs.vicinae.input-server.enable = config.dotfiles.modules.vicinae.enable;
        programs.vicinae.input-server.package = pkgs.vicinae;
      }
    )
  ]
  ++ importModules mkSystemModule "system/modules/nixos";
}
