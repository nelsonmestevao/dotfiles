# The opposite of ./enableFor.nix, with the same checks. enableFor is built
# once, so the work it does before taking `names` isn't redone on every call.
args:
let
  enableFor = import ./enableFor.nix args;
in
names: !(enableFor names)
