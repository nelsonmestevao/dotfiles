{
  pkgs,
  ...
}:
{
  # vicinae pastes text and expands snippets through a helper that needs extra
  # rights to reach the keyboard. This gives it those rights; nixpkgs has no
  # NixOS module that does. The home program points vicinae at this copy.
  security.wrappers.vicinae-input-server = {
    source = "${pkgs.vicinae}/libexec/vicinae/vicinae-input-server";
    capabilities = "cap_dac_override+ep";
    owner = "root";
    group = "root";
  };
}
