# mode and the three commands it switches: theme, caffeine and notifications.
# Each one is also a command of its own. They came from my spells repo, and
# came here because mode edits files in this repo.
#
# The xonsh scripts import scripts/spellbook.xsh, so it goes next to them.
# Each command runs its script with an interpreter from nixpkgs, so the
# shebang lines only matter when you run a script by hand.
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
  pname = "mode";
  version = "0.7.0";

  src = pkgs.lib.fileset.toSource {
    root = ../../..;
    fileset = pkgs.lib.fileset.unions [
      ./mode.sh
      ./theme.xsh
      ./caffeine.xsh
      ./notifications.xsh
      ../../../scripts/spellbook.xsh
    ];
  };

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  # theme, caffeine and notifications ask with gum when they get no argument.
  # mode needs GNU sed and grep (a Mac's take other flags), qmk_hid for the
  # keyboard light, and the other three commands. gsettings, osascript,
  # defaults and caffeinate come from the system.
  installPhase = ''
    runHook preInstall

    libexec=$out/libexec/mode
    install -Dm755 home/programs/mode/mode.sh "$libexec/mode"
    for command in theme caffeine notifications; do
      install -Dm755 "home/programs/mode/$command.xsh" "$libexec/$command"
      makeWrapper ${xonsh}/bin/xonsh "$out/bin/$command" \
        --add-flags "--no-rc $libexec/$command" \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.gum ]}
    done
    install -Dm644 scripts/spellbook.xsh "$libexec/spellbook.xsh"

    makeWrapper ${pkgs.bash}/bin/bash "$out/bin/mode" \
      --add-flags "$libexec/mode" \
      --prefix PATH : "$out/bin:${
        pkgs.lib.makeBinPath (
          with pkgs;
          [
            gnused
            gnugrep
          ]
          # Builds only on Linux, where the Framework keyboard is. On a Mac,
          # mode -k says it cannot reach the keyboard light.
          ++ lib.optional stdenv.hostPlatform.isLinux qmk_hid
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
