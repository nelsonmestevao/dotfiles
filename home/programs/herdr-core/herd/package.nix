# herd: open a Herdr space on a git worktree for a branch. It came from my
# spells repo, and lives with Herdr so it is only there when Herdr is.
#
# It imports scripts/spellbook.xsh, so that goes next to it. git, herdr-app
# and hc come from the system: git for its credentials, and the Herdr
# commands from Herdr itself.
{ pkgs }:
let
  xonsh = pkgs.xonsh.override {
    extraPackages =
      ps: with ps; [
        docopt
      ];
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "herd";
  version = "0.2.0";

  src = pkgs.lib.fileset.toSource {
    root = ../../../..;
    fileset = pkgs.lib.fileset.unions [
      ./herd.xsh
      ../../../../scripts/spellbook.xsh
    ];
  };

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    libexec=$out/libexec/herd
    install -Dm755 home/programs/herdr-core/herd/herd.xsh "$libexec/herd"
    install -Dm644 scripts/spellbook.xsh "$libexec/spellbook.xsh"
    makeWrapper ${xonsh}/bin/xonsh "$out/bin/herd" \
      --add-flags "--no-rc $libexec/herd" \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.gum ]}

    runHook postInstall
  '';

  meta = {
    description = "Open a Herdr space on a git worktree for a branch";
    mainProgram = "herd";
    platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
  };
}
