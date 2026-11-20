# Extensions that are only a package. Each name here is an extension like one
# in its own folder: it gets dotfiles.programs.gnome.extensions.<name>.enable,
# and a user file turns it on. Give an extension its own folder once it needs
# more than its package, like dconf settings.
pkgs: with pkgs.gnomeExtensions; {
  inherit
    accent-directories
    auto-move-windows
    color-picker
    draw-on-gnome
    just-perfection
    printers
    vitals
    wiggle
    ;

  # Newer than the ones in nixpkgs stable. caffeine needs v59 at least, for
  # its CLI tools.
  inherit (pkgs.unstable.gnomeExtensions)
    caffeine
    smart-home
    wake-on-lan
    ;
}
