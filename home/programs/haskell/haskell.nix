{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    ghc
    # haskell.compiler.ghc912
    haskellPackages.haskell-language-server

    # haskellPackages.lhs2tex
    haskellPackages.cabal-install
    # haskellPackages.hindent
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
    libx11
  ];

  # Where stack and cabal install commands.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Environment, not shell comfort: a script or an editor that builds Haskell
  # needs ghcup's paths and the OpenGL libraries too. So this stays in the
  # file every zsh reads, scripts included.
  programs.zsh.envExtra = ''
    [ -f ~/.ghcup/env ] && source ~/.ghcup/env
    export LD_LIBRARY_PATH="${pkgs.freeglut}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH"
  '';

  home.file.".ghci" = mkSymlink "ghci";
}
