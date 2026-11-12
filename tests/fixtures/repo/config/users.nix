# The users of the made-up fleet in ./hosts.nix.
{
  alice = {
    name = "Alice";
    extraGroups = [ "wheel" ];
  };
  bob = {
    name = "Bob";
  };
}
