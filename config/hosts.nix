# ── Hosts ──────────────────────────────────────────────────────────────────
#
# `platform` selects the system builder ("nixos" or "darwin"); omit it for
# hosts that only get a home-manager configuration.
{
  framework = {
    system = "x86_64-linux";
    platform = "nixos";
    users = [ "nelson" ];
  };
  thinkpad = {
    system = "x86_64-linux";
    users = [ "nelson" ];
  };
  temis = {
    system = "x86_64-linux";
    platform = "nixos";
    users = [ "nelson" ];
  };
  "Remote-Nelson-Estevao" = {
    system = "aarch64-darwin";
    platform = "darwin";
    users = [ "nelson.estevao" ];
  };
}
