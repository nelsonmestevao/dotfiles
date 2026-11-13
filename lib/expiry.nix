# Overrides that say when they can go.
#
# A package this repo patches or bumps waits for a fix that nixpkgs or its
# authors will ship one day. Nothing used to say when that day came, so a
# patch could stay long after it was needed. Wrapped in one of these, it is
# the same package, but once the fix is out, every `bin/check --eval`, build
# and switch prints a warning that names what to delete.
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
