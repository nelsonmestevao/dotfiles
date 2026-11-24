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

    libexec=$out/libexec/herd
    install -Dm755 home/programs/herd/herd.xsh "$libexec/herd"
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
