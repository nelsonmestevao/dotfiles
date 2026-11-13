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
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      vicinae,
      ...
    }:
    let
      inherit (nixpkgs) lib;

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
        checkedData
        nixosConfigs
        darwinConfigs
        homeConfigs
        ;
    in
    {
      formatter = lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # The packages this repo builds or changes itself, so each one can be
      # built alone, like `nix build .#git-sim`. lib/packages.nix finds them.
      packages = lib.genAttrs allSystems (import ./lib/packages.nix { inherit nixpkgs overlays; });

      # What the bin/ scripts and the lint check need. The scripts start in
      # this shell on their own; `nix develop` or direnv (.envrc) opens it.
      devShells = lib.genAttrs allSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              deadnix
              statix
              nixfmt
              gum
              # For .github/scripts/plan-builds and its tests.
              jq
              nh
              nix-diff
              python3
              python3Packages.xonsh
              python3Packages.docopt
              nix-update
            ];
          };
        }
      );

      checks = lib.genAttrs allSystems (
        import ./lib/checks.nix {
          inherit
            nixpkgs
            home-manager
            self
            checkedData
            nixosConfigs
            darwinConfigs
            homeConfigs
            ;
        }
      );

      nixosConfigurations = nixosConfigs;
      darwinConfigurations = darwinConfigs;
      homeConfigurations = homeConfigs;
    };
}
