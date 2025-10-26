{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
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

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    export PATH="$HOME/.local/bin:$PATH";
    [ -f ~/.ghcup/env ] && source ~/.ghcup/env
  '';

  home.file.".ghci" = mkSymlink "ghci";
}
