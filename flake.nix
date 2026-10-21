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
      # TODO: back to github:youwen5/zen-browser-flake once
      # https://github.com/youwen5/zen-browser-flake/pull/23 is merged
      url = "github:Brainlesslukas/zen-browser-flake/6ca1a282fa32f47cd9fd15ad8592e09558600da8";
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

    zed.url = "github:zed-industries/zed/v1.4.4";
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

      # ── Configuration ────────────────────────────────────────────────────
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

      # ── Assembly ─────────────────────────────────────────────────────────
      inherit
        (import ./lib {
          inherit
            nixpkgs
            home-manager
            nix-darwin
            vicinae
            hosts
            users
            ;
        })
        allSystems
        systemConfigsFor
        homeConfigs
        ;
    in
    {
      formatter = lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = lib.genAttrs allSystems (
        system:
        lib.mapAttrs (_: cfg: cfg.activationPackage) (
          lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) homeConfigs
        )
      );

      nixosConfigurations = systemConfigsFor "nixos";
      darwinConfigurations = systemConfigsFor "darwin";
      homeConfigurations = homeConfigs;
    };
}
