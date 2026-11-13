# `platform` selects the system builder ("nixos" or "darwin"); omit it for
# hosts that only get a home-manager configuration.
#
# `roles` say what a host is for ("desktop", "server"). User files turn
# programs on by role or host name, e.g. `enableFor [ "desktop" "temis" ]`, so
# a role can't share a host's name.
#
# Each host also gets a role for its OS, "linux" or "darwin", taken from its
# `system`. You don't need to list it.
#
# `stateVersion` is the release the host was first installed with. Home
# Manager and NixOS keep that release's defaults for stateful things (database
# layouts, file locations), so it stays put as the inputs move on. A Mac also
# sets `darwinStateVersion`, nix-darwin's own number, for the same reason.
#
# A host entry holds facts about the machine, not about one program. What a
# program needs per host (like the key that signs commits) is a setting of
# that program, set in the user file: see home/users/.
{
  framework = {
    system = "x86_64-linux";
    platform = "nixos";
    roles = [ "desktop" ];
    users = [ "nelson" ];
    stateVersion = "25.11";
  };
  thinkpad = {
    system = "x86_64-linux";
    users = [ "nelson" ];
    stateVersion = "25.11";
  };
  temis = {
    system = "x86_64-linux";
    platform = "nixos";
    roles = [ "server" ];
    users = [ "nelson" ];
    stateVersion = "25.11";
  };
  "Remote-Nelson-Estevao" = {
    system = "aarch64-darwin";
    platform = "darwin";
    roles = [ "desktop" ];
    users = [ "nelson.estevao" ];
    stateVersion = "25.11";
    darwinStateVersion = 6;
  };
}
