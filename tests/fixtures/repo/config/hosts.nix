# A made-up fleet for tests/lib.nix: one of each kind of host.
{
  # A NixOS desktop.
  box = {
    system = "x86_64-linux";
    platform = "nixos";
    roles = [ "desktop" ];
    users = [ "alice" ];
    stateVersion = "25.11";
  };
  # Another distro: home-manager only, and no roles.
  shed = {
    system = "x86_64-linux";
    users = [ "alice" ];
    stateVersion = "25.11";
  };
  # A Mac.
  mac = {
    system = "aarch64-darwin";
    platform = "darwin";
    roles = [ "desktop" ];
    users = [ "bob" ];
    stateVersion = "25.11";
    darwinStateVersion = 6;
  };
}
