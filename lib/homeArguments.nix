# The arguments every home module gets. ./schema.nix keeps a user's own
# `extraSpecialArgs` off these names, and ./mkHomeConfig.nix stops if this
# list and what it passes ever differ.
[
  "username"
  "hostname"
  "host"
  "user"
  "enableFor"
  "disableFor"
  "valueFor"
]
