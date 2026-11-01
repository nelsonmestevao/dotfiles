# ── Hosts ──────────────────────────────────────────────────────────────────
#
# `platform` selects the system builder ("nixos" or "darwin"); omit it for
# hosts that only get a home-manager configuration.
#
# `roles` say what a host is for ("desktop", "server"). User files turn
# programs on per role with `enableForRoles [ "desktop" ]`.
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
