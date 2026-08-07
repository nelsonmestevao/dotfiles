{
  description = "Nelson's Dotfiles";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zed = {
      url = "github:zed-industries/zed/v1.4.4";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      zen-browser,
      claude-code,
      codex-cli-nix,
      herdr,
      vicinae,
      zed,
    }:
    let
      lib = nixpkgs.lib;
      mkNixosConfig = import ./lib/mkNixosConfig.nix { inherit nixpkgs vicinae; };
      mkDarwinConfig = import ./lib/mkDarwinConfig.nix { inherit nixpkgs nix-darwin; };
      mkHomeConfig = import ./lib/mkHomeConfig.nix { inherit nixpkgs home-manager vicinae; };

      hosts = import ./config/hosts.nix;
      users = import ./config/users.nix {
        inherit
          nixpkgs-unstable
          claude-code
          codex-cli-nix
          herdr
          zen-browser
          zed
          ;
      };

      allSystems = lib.unique (lib.mapAttrsToList (_: h: h.system) hosts);

      homeConfigs = lib.concatMapAttrs (
        hostname: hostCfg:
        lib.listToAttrs (
          map (
            username:
            lib.nameValuePair "${username}@${hostname}" (
              mkHomeConfig hostCfg.system hostname username (users.${username})
            )
          ) hostCfg.users
        )
      ) hosts;
    in
    {
      formatter = lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = lib.genAttrs allSystems (
        system:
        lib.mapAttrs (_: cfg: cfg.activationPackage) (
          lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) homeConfigs
        )
      );

      nixosConfigurations = lib.mapAttrs mkNixosConfig (
        lib.mapAttrs (_: cfg: cfg // { users = lib.genAttrs cfg.users (u: users.${u}); }) (
          lib.filterAttrs (_: cfg: cfg.nixos or false) hosts
        )
      );

      darwinConfigurations = lib.mapAttrs mkDarwinConfig (
        lib.mapAttrs (_: cfg: cfg // { users = lib.genAttrs cfg.users (u: users.${u}); }) (
          lib.filterAttrs (_: cfg: cfg.darwin or false) hosts
        )
      );

      homeConfigurations = homeConfigs;
    };
}
