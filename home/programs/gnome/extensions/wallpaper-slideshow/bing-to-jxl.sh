# shellcheck shell=bash
#
# Turns the JPGs in a folder into JPEG XL and deletes the JPGs. The wallpaper
# slideshow's Bing downloader saves JPGs, and a systemd path unit runs this
# each time the folder changes (see wallpaper-slideshow.nix).
#
# cjxl stores a JPG losslessly: `djxl picture.jxl picture.jpg` gives back the
# very same file.
#
# Usage: bing-to-jxl <folder>

folder=$1
failed=0

shopt -s nullglob
for jpg in "$folder"/*.jpg; do
  jxl=${jpg%.jpg}.jxl

  # The patched downloader skips a picture that has a .jxl, so a JPG next to
  # one is an older second download of the same picture.
  if [[ -e $jxl ]]; then
    rm -- "$jpg"
    continue
  fi

  # Write to a hidden .part file first, so the slideshow never picks up a
  # half-written picture.
  part=$folder/.$(basename "$jxl").part
  if cjxl --quiet --lossless_jpeg=1 "$jpg" "$part"; then
    # Keep the download time, the only date the picture has.
    touch --reference="$jpg" "$part"
    mv -- "$part" "$jxl"
    rm -- "$jpg"
  else
    rm -f -- "$part"
    echo "bing-to-jxl: could not convert $jpg, so it stays a JPG" >&2
    failed=1
  fi
done

exit "$failed"
