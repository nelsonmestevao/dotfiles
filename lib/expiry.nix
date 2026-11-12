# Overrides that say when they can go.
#
# A package that this repo patches or bumps stands in for what upstream will
# ship one day. Nothing used to say when that day came, so an override could
# sit here long after it was needed. Wrapped in one of these, it stays the
# same package, but once upstream has caught up every evaluation
# (`bin/check --eval`, a build, a switch) warns and names what to delete.
#
# Use it as `pkgs.expiry`: config/overlays.nix adds it to every package set,
# so a file needs no path to this one.
lib: rec {
  # `expiresWhen caughtUp "What to delete." override` is `override`, with that
  # warning once `caughtUp` is true.
  expiresWhen =
    caughtUp: whatToDelete: override:
    lib.warnIf caughtUp "dotfiles: ${whatToDelete}" override;

  # The usual case: upstream's own package has reached `version`.
  #
  #   pkgs.expiry.untilUpstreamHas cmux.version pkgs.unstable.cmux "Delete home/programs/cmux/package.nix." cmux
  untilUpstreamHas =
    version: upstream: whatToDelete:
    expiresWhen (lib.versionAtLeast upstream.version version) "${lib.getName upstream} ${upstream.version} is out. ${whatToDelete}";
}
