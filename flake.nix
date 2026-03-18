{
  description = "Nelson's Dotfiles";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

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
      home-manager,
      zen-browser,
      claude-code,
    }:
    let
      lib = nixpkgs.lib;

      # ── Host definitions (system lives here, not on users) ────────────
      hosts = {
        framework = {
          system = "x86_64-linux";
          username = "nelson";
          name = "Nelson Estevão";
          modules = [ ./system/configuration.nix ];
        };
      };

      # ── User definitions (host-independent config only) ───────────────
      users = {
        nelson = {
          overlays = [ claude-code.overlays.default ];
          extraSpecialArgs = { inherit zen-browser; };
        };
      };

      # ── Helpers ────────────────────────────────────────────────────────
      mkHomeModules =
        let
          mkHomeModule = import ./home/lib/mkHomeModule.nix { inherit lib; };
        in
        map (name: mkHomeModule name (import ./home/programs/${name}/${name}.nix)) (
          lib.attrNames (builtins.readDir ./home/programs)
        );

      mkNixosConfig =
        hostname: cfg:
        nixpkgs.lib.nixosSystem {
          inherit (cfg) system;
          specialArgs = {
            inherit hostname;
            inherit (cfg) username name;
          };
          modules = cfg.modules;
        };

      mkHomeConfig =
        hostname: hostCfg:
        let
          userCfg = users.${hostCfg.username};
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${hostCfg.system};
          extraSpecialArgs = { inherit (hostCfg) username; } // (userCfg.extraSpecialArgs or { });
          modules =
            [
              { nixpkgs.overlays = userCfg.overlays or [ ]; }
              ./home
              ./home/lib
            ]
            ++ mkHomeModules;
        };

      allSystems = lib.unique (lib.mapAttrsToList (_: h: h.system) hosts);
    in
    {
      formatter = lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      nixosConfigurations = lib.mapAttrs mkNixosConfig hosts;

      homeConfigurations = lib.mapAttrs' (
        hostname: hostCfg:
        lib.nameValuePair "${hostCfg.username}@${hostname}" (mkHomeConfig hostname hostCfg)
      ) hosts;
    };
}
