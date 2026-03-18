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
      system = "x86_64-linux";
      hostname = "framework";
      username = "nelson";
      name = "Nelson Estevão";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      mkHomeModule = import ./home/lib/mkHomeModule.nix { inherit lib; };

      homeModules = map (name: mkHomeModule name (import ./home/programs/${name}/${name}.nix)) (
        lib.attrNames (builtins.readDir ./home/programs)
      );
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            hostname
            username
            name
            ;
        };
        modules = [ ./system/configuration.nix ];
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit username zen-browser; };
        modules = [
          {
            nixpkgs.overlays = [ claude-code.overlays.default ];
          }
          ./home
          ./home/lib
        ]
        ++ homeModules;
      };
    };
}
