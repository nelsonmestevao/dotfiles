# projectionist built from https://github.com/edsinclair/zed-projectionist/pull/2
# (**/* globs, deterministic matching, global projections and --editor).
#
# Upstream gitignores Cargo.lock, so one generated with `cargo generate-lockfile`
# lives next to this file. Regenerate it whenever `rev` changes.
{ pkgs }:
pkgs.rustPlatform.buildRustPackage {
  pname = "projectionist";
  version = "0.1.0-unstable-2026-10-21";

  src = pkgs.fetchFromGitHub {
    owner = "nelsonmestevao";
    repo = "projectionist.rs";
    rev = "710c3f061d6a8cd7fe0dabde05006234cbfc354d";
    hash = "sha256-5+H2iELVJ34Pr8iq+U5LgSf/bubIxADexSWApLOFoEU=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  meta = {
    description = "Project-aware file navigation via .projections.json (vim-projectionist port)";
    homepage = "https://github.com/edsinclair/zed-projectionist";
    license = pkgs.lib.licenses.mit;
    mainProgram = "projectionist";
  };
}
