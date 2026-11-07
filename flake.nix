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

    herdr-app-nix = {
      url = "github:TamagoMasgend/herdr-app-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    orca = {
      url = "github:stslex/orca-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nix-darwin,
      vicinae,
      ...
    }:
    let
      lib = nixpkgs.lib;

      # ── Configuration ────────────────────────────────────────────────────
      hosts = import ./config/hosts.nix;
      users = import ./config/users.nix;
      overlays = import ./config/overlays.nix inputs;

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
            overlays
            ;
        })
        allSystems
        systemConfigsFor
        homeConfigs
        ;

      nixosConfigs = systemConfigsFor "nixos";
      darwinConfigs = systemConfigsFor "darwin";

      # The hosts of `configs` that run on `system`, by host name.
      hostsOn = system: lib.filterAttrs (name: _: hosts.${name}.system == system);

      # A check that evaluates a system configuration without building it.
      # Working out the top-level derivation's path evaluates every module,
      # option and assertion, which is where configuration errors show up.
      # Building the closure would take hours on a runner. `nix flake check`
      # doesn't know darwinConfigurations at all, so this is the only check
      # the Mac system config gets.
      evalOnly =
        system: name: toplevel:
        nixpkgs.legacyPackages.${system}.runCommand "eval-${name}" {
          drvPath = builtins.unsafeDiscardStringContext toplevel.drvPath;
        } ''echo "$drvPath" > "$out"'';
    in
    {
      formatter = lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = lib.genAttrs allSystems (
        system:
        lib.mapAttrs (_: cfg: cfg.activationPackage) (
          lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) homeConfigs
        )
        // lib.mapAttrs' (
          name: cfg:
          lib.nameValuePair "nixos-${name}" (evalOnly system "nixos-${name}" cfg.config.system.build.toplevel)
        ) (hostsOn system nixosConfigs)
        // lib.mapAttrs' (
          name: cfg: lib.nameValuePair "darwin-${name}" (evalOnly system "darwin-${name}" cfg.system)
        ) (hostsOn system darwinConfigs)
      );

      nixosConfigurations = nixosConfigs;
      darwinConfigurations = darwinConfigs;
      homeConfigurations = homeConfigs;
    };
}
