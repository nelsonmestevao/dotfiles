# How a package installs a xonsh script that imports spellbook.xsh, for mode's
# and herd's package.nix.
{ pkgs }:
let
  xonsh = pkgs.xonsh.override {
    extraPackages =
      ps: with ps; [
        docopt
      ];
  };
in
{
  # `installXonshScript "herd" "home/programs/herd/herd.xsh"` gives the
  # installPhase lines for bin/herd. It runs the script with a xonsh that has
  # docopt and with gum on PATH, and puts spellbook.xsh next to the script.
  # The package's src must hold the script and scripts/spellbook.xsh.
  installXonshScript = name: script: ''
    install -Dm755 ${script} "$out/libexec/${name}/${name}"
    install -Dm644 scripts/spellbook.xsh "$out/libexec/${name}/spellbook.xsh"
    makeWrapper ${xonsh}/bin/xonsh "$out/bin/${name}" \
      --add-flags "--no-rc $out/libexec/${name}/${name}" \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.gum ]}
  '';
}
