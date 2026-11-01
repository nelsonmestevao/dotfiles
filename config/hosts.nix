# ── Hosts ──────────────────────────────────────────────────────────────────
#
# `platform` selects the system builder ("nixos" or "darwin"); omit it for
# hosts that only get a home-manager configuration.
#
# `roles` say what a host is for ("desktop", "server"). User files turn
# programs on by role or host name, e.g. `enableFor [ "desktop" "temis" ]`, so
# a role can't share a host's name.
{
  framework = {
    system = "x86_64-linux";
    platform = "nixos";
    roles = [ "desktop" ];
    users = [ "nelson" ];
  };
  thinkpad = {
    system = "x86_64-linux";
    users = [ "nelson" ];
  };
  temis = {
    system = "x86_64-linux";
    platform = "nixos";
    roles = [ "server" ];
    users = [ "nelson" ];
  };
  "Remote-Nelson-Estevao" = {
    system = "aarch64-darwin";
    platform = "darwin";
    roles = [ "desktop" ];
    users = [ "nelson.estevao" ];
  };
}
