# ── Users (home-manager) ───────────────────────────────────────────────────
#
# Overlays are shared by every host and user; see ./overlays.nix.
{
  "nelson.estevao" = {
    name = "Nelson Estevão";
    extraGroups = [
      "docker"
    ];
    extraSpecialArgs = { };
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
    extraSpecialArgs = { };
  };
}
