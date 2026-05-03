{
  description = "Nelson's Dotfiles";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zed = {
      url = "github:zed-industries/zed/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      zen-browser,
      claude-code,
      vicinae,
      zed,
    }:
    let
      lib = nixpkgs.lib;
      mkNixosConfig = import ./lib/mkNixosConfig.nix { inherit nixpkgs; };
      mkHomeConfig = import ./lib/mkHomeConfig.nix { inherit nixpkgs home-manager vicinae; };

      # ── Hosts ────────────────────────────────────────────────────────────
      hosts = {
        framework = {
          system = "x86_64-linux";
          nixos = true;
          users = [ "nelson" ];
        };
        thinkpad = {
          system = "x86_64-linux";
          nixos = false;
          users = [ "nelson" ];
        };
        temis = {
          system = "x86_64-linux";
          nixos = true;
          users = [ "nelson" ];
        };
      };

      # ── Users (home-manager) ─────────────────────────────────────────────
      users = {
        nelson = {
          name = "Nelson Estevão";
          extraGroups = [
            "docker"
            "libvirtd"
            "lpadmin"
            "networkmanager"
            "wheel"
          ];
          overlays = [
            claude-code.overlays.default
            (final: prev: { zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default; })
            (final: prev: { zed-editor = zed.packages.${prev.stdenv.hostPlatform.system}.default; })
            (final: prev: {
              unstable = import nixpkgs-unstable {
                system = prev.stdenv.hostPlatform.system;
                config.allowUnfree = true;
              };
            })
          ];
          extraSpecialArgs = { };
        };
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
          lib.filterAttrs (_: cfg: cfg.nixos) hosts
        )
      );

      homeConfigurations = homeConfigs;
    };
}
