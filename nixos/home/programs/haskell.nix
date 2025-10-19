{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.haskell;
in
{
  options.dotfiles.programs.haskell = {
    enable = lib.mkEnableOption "Enable Haskell development environment.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      ghc
      haskell-language-server

      haskellPackages.lhs2tex
      haskellPackages.cabal-install
      haskellPackages.hindent
      haskellPackages.hlint

      # haskellPackages.HUnit
      # haskellPackages.gloss

      # haskellPackages.pandoc
      # haskellPackages.pandoc-citeproc
      # haskellPackages.pandoc-include-code
      # haskellPackages.patat

      # OpenGL
      freeglut
      libGL
      libGLU
      libGLU.dev
      mesa
      mesa_glu
    ];

    home.file.".ghci" = config.lib.dotfiles.mkSymlink "nixos/home/programs/haskell/ghci";
  };
}
