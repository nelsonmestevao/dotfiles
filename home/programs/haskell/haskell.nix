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
    # haskell.compiler.ghc912
    haskellPackages.haskell-language-server

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
    xorg.libX11
  ];

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    export PATH="$HOME/.local/bin:$PATH";
    [ -f ~/.ghcup/env ] && source ~/.ghcup/env
    export LD_LIBRARY_PATH="${pkgs.freeglut}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH"
  '';

  home.file.".ghci" = mkSymlink "ghci";
}
