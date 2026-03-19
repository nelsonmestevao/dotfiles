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
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      zen-browser,
      claude-code,
    }:
    let
      lib = nixpkgs.lib;
      mkHomeModules = import ./lib/mkHomeModules.nix { inherit lib; };
      mkNixosConfig = import ./lib/mkNixosConfig.nix { inherit nixpkgs; };
      mkHomeConfig = import ./lib/mkHomeConfig.nix { inherit nixpkgs home-manager mkHomeModules; };

      # ── Hosts ────────────────────────────────────────────────────────────
      hosts = {
        framework = {
          system = "x86_64-linux";
          modules = [ ./system/configuration.nix ];
          users = {
            nelson = {
              name = "Nelson Estevão";
            };
          };
        };
        thinkpad = {
          system = "x86_64-linux";
          users = {
            nelson = {
              name = "Nelson Estevão";
            };
          };
        };
      };

      # ── Users (home-manager) ─────────────────────────────────────────────
      users = {
        nelson = {
          overlays = [
            claude-code.overlays.default
            (final: prev: { zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default; })
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
    in
    {
      formatter = lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      nixosConfigurations = lib.mapAttrs mkNixosConfig (lib.filterAttrs (_: cfg: cfg ? modules) hosts);

      homeConfigurations = lib.concatMapAttrs (
        hostname: hostCfg:
        lib.mapAttrs' (
          username: _:
          lib.nameValuePair "${username}@${hostname}" (
            mkHomeConfig hostCfg.system hostname username (users.${username})
          )
        ) hostCfg.users
      ) hosts;
    };
}
