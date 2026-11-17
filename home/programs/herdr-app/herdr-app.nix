{
  config,
  lib,
  pkgs,
  mkSymlink,
  checkoutPath,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Every folder in mods/ is copied, and every file in layouts/ is linked into
  # ~/.config/herdr-app/layouts, so deleting one is enough to drop it.
  # main-mods and most mods are mine. call, chat, pasture, threads and the
  # t4-* mods come from herdrdev/herdr-layout-examples (Apache-2.0).
  # ctrl-shift-l cycles the layouts.
  mods = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./mods));
  layouts = lib.attrNames (builtins.readDir ./layouts);
in
{
  # On macOS, Herdr.app installs and updates itself (herdr-app, hc and
  # herdr-core in ~/.local/bin), so Nix only links the config there.
  home.packages = lib.optional (!isDarwin) pkgs.herdr-app;

  # Herdr writes through these links (settings, zoom, theme picks), but it
  # doesn't see edits made through them while running. After changing a file
  # by hand, `touch -h ~/.config/herdr-app/<file>` reloads it. Herdr owns
  # everything else in the folder.
  xdg.configFile = {
    "herdr-app/keys.json" = mkSymlink (if isDarwin then ./keys/macos.json else ./keys/linux.json);
    "herdr-app/settings.json" = mkSymlink ./settings.json;
  }
  // lib.genAttrs' layouts (f: lib.nameValuePair "herdr-app/layouts/${f}" (mkSymlink ./layouts/${f}));

  # Mods are copies, not links: Herdr refuses to follow a link out of
  # ~/.config/herdr-app for a mod's imports and its images (`svg()`,
  # `image()`), so a linked mod loses its icons and a linked file breaks its
  # imports. Every switch copies the repo's mods over, so edit them in the
  # repo, not in ~/.config/herdr-app/mods: a switch overwrites edits there.
  # A mod whose folder is gone from the repo is deleted on the next switch;
  # the marker file says which folders are ours.
  home.activation.herdrAppMods = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    src=${lib.escapeShellArg (checkoutPath ./mods)}
    dst=${lib.escapeShellArg "${config.xdg.configHome}/herdr-app/mods"}
    mods=(${lib.escapeShellArgs mods})
    marker=.from-dotfiles

    for old in "$dst"/*/; do
      old=''${old%/}
      [[ -e $old/$marker ]] || continue
      [[ " ''${mods[*]} " == *" ''${old##*/} "* ]] || run rm -rf "$old"
    done

    for m in "''${mods[@]}"; do
      [[ -L $dst/$m ]] && run rm "$dst/$m"
      run mkdir -p "$dst/$m"
      # --delete drops files gone from the repo; excluded files (what Herdr
      # writes into each mod, downloads, the marker) are kept.
      run ${lib.getExe pkgs.rsync} -rt --delete --no-links \
        --exclude gpui-kit.d.ts --exclude jsconfig.json --exclude .cache --exclude "$marker" \
        "$src/$m/" "$dst/$m/"
      run touch "$dst/$m/$marker"
    done
  '';
}
