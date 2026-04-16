{ pkgs }:
let
  uuid = "rudra@narkagni";
in
pkgs.stdenv.mkDerivation {
  pname = "gnome-shell-extension-rudra";
  version = "unstable-2026-04-16";

  src = pkgs.fetchFromGitHub {
    owner = "narkagni";
    repo = "rudra";
    rev = "ecc3abd5b52f0cd1e698967dbdacbebad264bbbe";
    hash = "sha256-ddy0oEohJHbA09pAuFYFmo418bupQcAJIeVrjnaafEw=";
  };

  patches = [ ./rudra-ctrl-pn.patch ];

  nativeBuildInputs = [ pkgs.glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ext=$out/share/gnome-shell/extensions/${uuid}
    mkdir -p $ext
    cp extension.js prefs.js stylesheet.css metadata.json $ext/
    cp -r icons schemas src $ext/
    runHook postInstall
  '';

  passthru.extensionUuid = uuid;
}
