# projectionist built from https://github.com/edsinclair/zed-projectionist/pull/2
# (**/* globs, deterministic matching, global projections, --editor, alternate
# lists and vim-projectionist placeholder transforms).
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
    rev = "7994c04efa00c55d70293b419c5b9ba2e108b4ba";
    hash = "sha256-1oao3WSdoAT3shUMeUsG8XW2xONZ46CkDsnLOEvoEyY=";
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
