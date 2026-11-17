# Wallpaper Slideshow with two fixes:
#
# - date-order.patch: with the queue sorted by "Newest" or "Oldest", a new
#   picture went to the wrong end of the queue, because insertWallpaper()
#   compared the dates backwards. Upstream's main branch still does.
# - skip-jxl.patch: the Bing downloader only looked for <name>.jpg. Once that
#   JPG was converted to JPEG XL, it downloaded the same picture again. This
#   repo keeps only the .jxl (see bing-to-jxl.sh), so upstream won't need it.
{ pkgs }:
let
  upstream = pkgs.gnomeExtensions.wallpaper-slideshow;
  # The version the patches were made for. Any other one warns, so someone
  # checks that they still apply and are still needed.
  patchedFor = "19";
in
pkgs.expiry.expiresWhen (upstream.version != patchedFor)
  "wallpaper-slideshow is now ${upstream.version}. Check its patches in home/programs/gnome/extensions/wallpaper-slideshow/package.nix: drop date-order.patch if upstream fixed insertWallpaper(), then set patchedFor there."
  (
    upstream.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./date-order.patch
        ./skip-jxl.patch
      ];
    })
  )
