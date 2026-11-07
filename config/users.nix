# ── Users (home-manager) ───────────────────────────────────────────────────
#
# Overlays are shared by every host and user; see ./overlays.nix.
#
# `git.profile` names the file in home/programs/git/profiles/ that git
# includes for this user (identity, per-folder identities). Leave it out and
# only the shared settings apply.
{
  "nelson.estevao" = {
    name = "Nelson Estevão";
    extraGroups = [
      "docker"
    ];
    extraSpecialArgs = { };
    git.profile = "remote";
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
    git.profile = "personal";
  };
}
