{ pkgs }:
let
  src = pkgs.fetchFromGitHub {
    owner = "donnybeelo";
    repo = "gnome-extensions-glocalsend";
    rev = "7b5a24ea633bcca8e58985fd9f1ca537df396168";
    hash = "sha256-13v83/WO0MzjXTJ9QRfYiq1YtHiarXEJQC8XB2FNg4g=";
  };

  deps = pkgs.stdenv.mkDerivation {
    pname = "gnome-shell-extension-glocalsend-deps";
    version = "unstable-2026-04-16";

    inherit src;

    nativeBuildInputs = [
      pkgs.bun
      pkgs.cacert
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      export HOME=$TMPDIR
      bun install --frozen-lockfile --ignore-scripts
      cp -r node_modules $out
      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-ezY3xLLo02BEwf8p6rLGsYfslr3o4IEkaE1SD3vV0Qo=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "gnome-shell-extension-glocalsend";
  version = "unstable-2026-04-16";

  inherit src;

  nativeBuildInputs = [
    pkgs.bun
    pkgs.glib
  ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    cp -r ${deps} node_modules
    chmod -R +w node_modules
    bun run node_modules/typescript/bin/tsc
    glib-compile-schemas schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ext=$out/share/gnome-shell/extensions/glocalsend@donnybeelo.github.com
    mkdir -p $ext/schemas
    cp dist/*.js $ext/
    cp metadata.json icon-symbolic.svg $ext/
    cp schemas/org.gnome.shell.extensions.glocalsend.gschema.xml $ext/schemas/
    cp schemas/gschemas.compiled $ext/schemas/
    runHook postInstall
  '';

  passthru.extensionUuid = "glocalsend@donnybeelo.github.com";
}
