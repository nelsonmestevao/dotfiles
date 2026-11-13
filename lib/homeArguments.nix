# The arguments every home module gets. ./schema.nix keeps a user's own
# `extraSpecialArgs` off them, and ./mkHomeConfig.nix stops the build if it
# passes any other set.
[
  "username"
  "hostname"
  "host"
  "user"
  "enableFor"
  "disableFor"
  "valueFor"
]
