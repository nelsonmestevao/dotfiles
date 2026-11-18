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

    # No follows: vicinae must use its own nixpkgs, so the build matches the one
    # in vicinae.cachix.org and is downloaded instead of compiled.
    vicinae.url = "github:vicinaehq/vicinae";

    crit = {
      url = "github:tomasz-tomczyk/crit";
      inputs.nixpkgs.follows = "nixpkgs";
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
        toolSystems
        hostSystems
        checkedData
        dataIsRight
        nixosConfigs
        darwinConfigs
        homeConfigs
        ;
    in
    {
      formatter = lib.genAttrs toolSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # The packages this repo builds or changes itself, so each one can be
      # built alone, like `nix build .#git-sim`. lib/packages.nix finds them.
      packages = lib.genAttrs hostSystems (import ./lib/packages.nix { inherit nixpkgs overlays; });

      # What the bin/ scripts need; the lint check brings its own tools (see
      # lib/checks.nix). The scripts start in this shell on their own, and
      # `nix develop` or direnv (.envrc) opens it.
      devShells = lib.genAttrs toolSystems (
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

      checks = lib.genAttrs hostSystems (
        import ./lib/checks.nix {
          inherit
            nixpkgs
            home-manager
            self
            checkedData
            dataIsRight
            nixosConfigs
            darwinConfigs
            homeConfigs
            ;
        }
      );

      # The cases in tests/lib.nix and tests/docs.nix, for nix-unit, which the
      # check `lib-tests` runs. They sit under `lib` because `nix flake check`
      # warns about an output it doesn't know, like `tests`.
      lib.tests = import ./tests/lib.nix { inherit nixpkgs home-manager; };

      nixosConfigurations = nixosConfigs;
      darwinConfigurations = darwinConfigs;
      homeConfigurations = homeConfigs;
    };
}
