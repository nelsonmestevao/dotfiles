{ pkgs }:
let
  inherit (import ../../../scripts/spellbook.nix { inherit pkgs; }) installXonshScript;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "mode";
  version = "0.8.0";

  src = pkgs.lib.fileset.toSource {
    root = ../../..;
    fileset = pkgs.lib.fileset.unions [
      ./mode.xsh
      ./theme.xsh
      ./caffeine.xsh
      ./notifications.xsh
      ../../../scripts/spellbook.xsh
    ];
  };

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    ${installXonshScript "theme" "home/programs/mode/theme.xsh"}
    ${installXonshScript "caffeine" "home/programs/mode/caffeine.xsh"}
    ${installXonshScript "notifications" "home/programs/mode/notifications.xsh"}
    ${installXonshScript "mode" "home/programs/mode/mode.xsh"}

    # mode runs the other three commands.
    wrapProgram "$out/bin/mode" \
      --prefix PATH : "$out/bin:${
        pkgs.lib.makeBinPath (
          with pkgs;
          # Builds only on Linux, where the Framework keyboard is. On a Mac,
          # mode -k says it cannot reach the keyboard light.
          lib.optional stdenv.hostPlatform.isLinux qmk_hid
        )
      }"

    runHook postInstall
  '';

  meta = {
    description = "Switch the screen set-up between working alone and showing your screen";
    mainProgram = "mode";
    platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
  };
}
