# The opposite of ./enableFor.nix, with the same checks.
args: names: !(import ./enableFor.nix args names)
