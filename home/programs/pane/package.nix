{ pkgs }:
let
  pname = "pane";
  version = "2.4.193";

  # Prebuilt releases: there is no nixpkgs package or upstream flake.
  # Hashes come from the release's SHA256SUMS.txt.
  sources = {
    x86_64-linux = {
      asset = "linux-x86_64.AppImage";
      hash = "sha256-pYp9otuxDMjnMmYzDJbpMZGEkSXqz/MUv6VMMtKjSYo=";
    };
    aarch64-linux = {
      asset = "linux-arm64.AppImage";
      hash = "sha256-8WLeu13H0rRSWy5Xw05AaWvIS3A9qNapq2DsdDS1iIg=";
    };
    x86_64-darwin = {
      asset = "macOS-x64.zip";
      hash = "sha256-26Bn8fkm6z01zFJ4GNiRPKTTnA8I80KxOCywewwLMyM=";
    };
    aarch64-darwin = {
      asset = "macOS-arm64.zip";
      hash = "sha256-X6YuXWztFsYxWe9dopGGS7Qugm5FT5xiceZ6UPuWxts=";
    };
  };

  source = sources.${pkgs.stdenv.hostPlatform.system};

  src = pkgs.fetchurl {
    url = "https://github.com/greenfield-inc/Pane/releases/download/v${version}/Pane-${version}-${source.asset}";
    inherit (source) hash;
  };

  meta = {
    description = "Terminal-first desktop app for running AI coding agents in parallel";
    homepage = "https://runpane.com";
    license = pkgs.lib.licenses.agpl3Only;
    platforms = builtins.attrNames sources;
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    mainProgram = "pane";
  };
in
if pkgs.stdenv.hostPlatform.isDarwin then
  pkgs.stdenvNoCC.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ pkgs.unzip ];

    sourceRoot = "Pane.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Pane.app
      cp -R . $out/Applications/Pane.app
      runHook postInstall
    '';
  }
else
  let
    extracted = pkgs.appimageTools.extract { inherit pname version src; };
  in
  pkgs.appimageTools.wrapType2 {
    inherit
      pname
      version
      src
      meta
      ;

    extraInstallCommands = ''
      install -Dm444 ${extracted}/pane.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/pane.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=pane %U'
      cp -r ${extracted}/usr/share/icons $out/share
    '';
  }
