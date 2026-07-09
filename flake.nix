{
  description = "Nelson's Dotfiles";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
      zen-browser,
      claude-code,
      herdr,
      vicinae,
      zed,
    }:
    let
      lib = nixpkgs.lib;
      mkNixosConfig = import ./lib/mkNixosConfig.nix { inherit nixpkgs vicinae; };
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
        "Remote-Nelson-Estevao" = {
          system = "aarch64-darwin";
          nixos = false;
          users = [ "nelson.estevao" ];
        };
      };

      # ── Users (home-manager) ─────────────────────────────────────────────
      users = {
        "nelson.estevao" = {
          name = "Nelson Estevão";
          extraGroups = [
            "docker"
          ];
          overlays = [
            claude-code.overlays.default
            herdr.overlays.default
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
            herdr.overlays.default
            (final: prev: { zen-browser = zen-browser.packages.${prev.stdenv.hostPlatform.system}.default; })
            # TODO: Remove this once GNOME 50 is released
            # GNOME 50 patch while waiting for PR #506387 to be merged
            # https://github.com/NixOS/nixpkgs/pull/506387
            (final: prev: {
              gnomeExtensions = prev.gnomeExtensions // {
                pop-shell = prev.gnomeExtensions.pop-shell.overrideAttrs (_: {
                  version = "1.2.0-unstable-2026-03-31";

                  src = prev.fetchFromGitHub {
                    owner = "pop-os";
                    repo = "shell";
                    rev = "7898b65c20735057faf0797f8ed056704ca55f0d";
                    hash = "sha256-MmHoOxymo0QSRbRcSbFiv82+QWAwIwXwg/wyGQGVYiI=";
                  };
                });
              };
            })
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
