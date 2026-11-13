# Overlays are shared by every host and user; see ./overlays.nix.
#
# A user's git identity is home/programs/git/profiles/<username>.ini.
{
  "nelson.estevao" = {
    name = "Nelson Estevão";
    extraGroups = [
      "docker"
    ];
  };
  nelson = {
    name = "Nelson Estevão";
    extraGroups = [
      "docker"
      "libvirtd"
      "lpadmin"
      "networkmanager"
      "wheel"
    ];
  };
}
