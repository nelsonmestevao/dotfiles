{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../lib
  ];

  home.packages = with pkgs; [
    ghc
    haskell-language-server

    haskellPackages.lhs2tex
    haskellPackages.cabal-install
    haskellPackages.hindent
    haskellPackages.hlint

    haskellPackages.HUnit
    haskellPackages.gloss

    # haskellPackages.pandoc
    # haskellPackages.pandoc-citeproc
    # haskellPackages.pandoc-include-code
    # haskellPackages.patat
  ];

  home.file.".ghci" = config.lib.dotfiles.mkSymlink "nixos/home/programs/haskell/ghci";
}
