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

  # The OpenGL libraries, for programs built with freeglut. Set once per
  # session, not by every shell, so it doesn't grow in nested shells. It has no empty entry when it was
  # unset, since that would make programs look for libraries in the current
  # folder.
  home.sessionVariables.LD_LIBRARY_PATH = "${pkgs.freeglut}/lib:${pkgs.libGL}/lib\${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}";

  # ghcup's paths, when ghcup is installed. In the file every zsh reads, so
  # scripts and editors that build Haskell get them too.
  programs.zsh.envExtra = ''
    [ -f ~/.ghcup/env ] && source ~/.ghcup/env
  '';

  home.file.".ghci" = mkSymlink "ghci";
}
