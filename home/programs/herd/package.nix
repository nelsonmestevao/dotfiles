{ pkgs }:
let
  inherit (import ../../../scripts/spellbook.nix { inherit pkgs; }) installXonshScript;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "herd";
  version = "0.2.0";

  src = pkgs.lib.fileset.toSource {
    root = ../../..;
    fileset = pkgs.lib.fileset.unions [
      ./herd.xsh
      ../../../scripts/spellbook.xsh
    ];
  };

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    ${installXonshScript "herd" "home/programs/herd/herd.xsh"}

    runHook postInstall
  '';

  meta = {
    description = "Open a Herdr space on a git worktree for a branch";
    mainProgram = "herd";
    platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
  };
}
