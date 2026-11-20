# The scripts in bin/ and .github/scripts/ of the repo at `root`, sorted by
# ./scriptKind.nix, like { shell = [ "bin/lint" … ]; xonsh = [ "bin/check" … ]; }.
# A script of neither kind stops the evaluation, so `bin/check --eval` names it
# too. The lint check and the formatter both read this, so a new script is
# checked and formatted without being listed anywhere.
{ lib }:
root:
lib.groupBy (import ./scriptKind.nix { inherit lib; } "${root}") (
  lib.concatMap
    (folder: map (name: "${folder}/${name}") (lib.attrNames (builtins.readDir "${root}/${folder}")))
    [
      "bin"
      ".github/scripts"
    ]
)
