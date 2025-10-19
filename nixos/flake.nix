{
  description = "Nelson's Dotfiles";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      zen-browser,
    }:
    let
      system = "x86_64-linux";
      hostname = "framework";
      username = "nelson";
      pkgs = nixpkgs.legacyPackages.${system};

      dotfilesModulesDir = builtins.readDir ./home/programs;
      dotfilesHomeModules = builtins.map (name: ./home/programs/${name}) (
        builtins.filter (name: dotfilesModulesDir.${name} == "regular") (
          builtins.attrNames dotfilesModulesDir
        )
      );
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit zen-browser hostname username; };
        modules = [ ./system/configuration.nix ];
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit username; };
        modules = [
          ./home
          ./home/lib
        ]
        ++ dotfilesHomeModules;
      };
    };
}
