# `nix fmt`, which bin/format runs: one command for every language this repo
# formats. The lint check runs the same one and fails on a file it would
# change (see ./checks.nix).
#
# It is nixpkgs' nixfmt-tree, which formats Nix, with shell and Lua added.
# JavaScript is left out on purpose: the Herdr mods are written densely, and
# a formatter would triple their length. The lint check only parses them.
#
# `root` is the repo, to find the shell scripts that have no `.sh` in their
# name.
{
  lib,
  pkgs,
  root,
}:
let
  scripts = import ./scripts.nix { inherit lib; } root;
in
pkgs.nixfmt-tree.override {
  runtimeInputs = with pkgs; [
    shfmt
    stylua
  ];

  settings.formatter = {
    # Two spaces, `case` branches indented, and a space after `>`: how the
    # scripts here are written already.
    shfmt = {
      command = "shfmt";
      options = [
        "--write"
        "--indent=2"
        "--case-indent"
        "--space-redirects"
      ];
      includes = [ "*.sh" ] ++ (scripts.shell or [ ]);
    };

    stylua = {
      command = "stylua";
      options = [
        "--indent-type=Spaces"
        "--indent-width=2"
        "--column-width=120"
      ];
      includes = [ "*.lua" ];
    };
  };
}
